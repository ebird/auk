#This file contains R script to create zero-filled (i.e. presence-absence) data from the 
# data distributed as the eBird Basic Dataset (EBD).  This zero-filling is possible because
# one of the two distributed tables is the "sampling" data: information from only the 
# SUB table, for every checklist that was not flagged as invalid.  When this information
# all possible checklists that are complete (i.e. that are reported by observers as 
# containing records of all bird species that the observer(s) saw and identified) is 
# combined with information from the other EBD table, we know which of the entire set 
# of complete checklists reported a species...and all of the other complete checklists
# by extension did not contain a record of that species.
#In the approach used below, we create subsets of the two EBD data tables that have 
# identical sets of columns (aside from the lack of species-specific columns from the
# "sampling" data; this process is done prior to defining the function "ZeroFillEBD"), 
# and then use the function "ZeroFillEBD" to add columns of species-specific information
# for a user-designated species onto the "sampling" data in order to produce 2 data.frames
# that are identical in their columns (both column names and column order).  Within the 
# function, the two tables are combined (using "rbind").  At this point, for every true
# record of a species there is also another near-identical record for which a count of
# zero individuals is listed for the designated species.  These fake zero records and true
# records are combined using "aggregate" to sum the actual and zero counts to leave only
# the actual non-zero counts; the zero records for checklists that did not report the
# designated species are passed through unchanged.
#Note that there is an alternate approach that would involve starting with the "sampling"
# data and first adding columns of information for actual observations, followed by adding
# zero-count information for all remaining records.  I have not tried to create a script
# that uses this alternate approach to zero-filling, but potentially the result would
# be somewhat faster and lighter-weight memory-wise...or maybe not to any useful
# extent.
#Anyway, after creating the zero-filled data.table, there is still another step that is
# needed for most uses: collapsing down the multiple and identical to near-identical
# verions of checklists that form part of a shared group.  This is the job of the 
# second function created in this script: "MergeGroupCountsToMax".  I chose to keep
# this as a separate task rather than hard-wiring it into the "ZeroFillEBD" function
# to allow users the option of retaining all copies of a shared list.  However, it
# probably would make more sense to have "ZeroFillEBD" call "MergeGroupCountsToMax"
# by default, and leave users the option to set a logical flag to FALSE if they
# so choose.
#As a general note, I have deliberately tried to use only functions in base R, even
# though the use of optional libraries could either speed processing or better deal 
# with very large input data files.  My thinking is that using just base R causes 
# less friction for potential users (i.e. we don't need to check for the presence of
# a library and ask users to install it), and also optional libraries might be more
# likely to break through time.
#This R script was assembled by Wesley Hochachka on 30 May 2017 from bits and pieces
# that I've created for one-off jobs over the last few months.  There are example
# data run through the processing, with these example data coming from the Feb 2017
# EBD for all of South America (well...excluding the Falkland Islands), with 
# a single species of birds, Plain Tyrannulet.  This location and species just happen
# to be data that I have been playing at present.  I've not tried running any data
# files larger than a handful of U.S. states through this processing, so there are
# no guarantees that the functions would work well for all of North America.


####################################################################################
############################# Initial preparatory work #############################
####################################################################################
#
#Specify the path for input data, and then set the working directory to 
# this location.
InputDir <- "C:/Users/Wes/Data_Sets/eBird/EBD_versions/Feb2017"
setwd(InputDir)

#Read in the two sets of data: one the "positive-only" data (records of species that
# were detected, and associated information about the data-collection event), and the
# second data table is list of all of the data-collection events, data that are needed
# in order to zero-fill the data (i.e. in order to add records of zero individuals
# for any one species).
IneziaData <- read.csv("SouthAmerica_Inezia_inornata_output.csv", header = T, stringsAsFactors = F)
SamplingData <- read.csv("SouthAmerica_sampling_output.csv", header = T, stringsAsFactors = F)

#Now we prepare for zero-filling.  The first step is to retain only the records from
# complete checklists.  Also, use only those records of bird species that are valid (i.e.
# either REVIEWED and APPROVED, or not REVIEWED; this step may not be needed). Finally, 
# create a numeric presence/absence version of the counts of birds (for which we can 
# use the "X" records of at least one bird of a species being present), and then tweak 
# the OBSERVED.COUNT variable so that the "X" values are replaced by missing values 
# and the variable is converted to numeric.  Note that while it is probably essentially 
# fine to create the presence/absence version of bird counts by just creating a whole 
# column with the values of "1", because all records in BirdComplete should be records 
# of a species being present, I'm paranoid that potentially a value of zero could sneak 
# into the data.
BirdComplete <- IneziaData[IneziaData$ALL.SPECIES.REPORTED == 1,]
#The following step is not needed for the EBD, as all data should have been validated.
BirdComplete <- BirdComplete[(BirdComplete$REVIEWED == 1 & BirdComplete$APPROVED == 1) | BirdComplete$REVIEWED == 0,]
PresAbs <- BirdComplete$OBSERVATION.COUNT
PresAbs[PresAbs == "X"] <- "1"
PresAbs <- as.numeric(PresAbs)
PresAbs[PresAbs > 1] <- 1
BirdComplete <- cbind(BirdComplete, PresAbs)
rm(PresAbs)
 #
#Now deal with counts of "X" birds in the OBSERVATION.COUNT column by turning
# them into NAs.
BirdComplete[BirdComplete$OBSERVATION.COUNT == "X",]$OBSERVATION.COUNT <- NA
BirdComplete$OBSERVATION.COUNT <- as.numeric(BirdComplete$OBSERVATION.COUNT)
 #
#Create a subset of the "sampling" data that only includes the complete lists,
# the group for which zero filling is logically possible.
SamplingComplete <- SamplingData[SamplingData$ALL.SPECIES.REPORTED == 1,]
 #
#Tidy up if we need to claw back some RAM.
rm(IneziaData, SamplingData)
 #
#Now, retain only a proportion of the columns that we (hopefully) really need for
# analyses, with the same subset of columns from each of the data.frames (i.e. for
# both data from the "bird" and the "sampling" tables of the EBD). Also, reorganize 
# the ordering of the columns a bit.  This is done in a 2-step process in which the
# first step is creating a vector of the names of the columns to keep, and the order
# in which they are to placed in the resultant data.frame.  I have used this initial 
# step because the information in the "ColumnsToKeep" vector is reused in places 
# throughout this function.  All of the columns unique to BirdComplete  are found at 
# the end of the re-organized data.frame.  We start with reorganizing BirdComplete.  
# We define the list of columns to keep buried here, although potentially and for the 
# sake of generality we probably should bundle up this initial data-preparation work
# into a function in which we allow users the  option of specifying a different list 
# and ordering of columns.  The current list and order is just the one that contains
# all of the information that I have ever found useful, and ordered in a way that 
# seems logical to me.
ColumnsToKeep <- c("STATE.CODE", "LOCALITY.ID", "OBSERVER.ID",
                   "SAMPLING.EVENT.IDENTIFIER", "GROUP.IDENTIFIER", "PROTOCOL.TYPE", 
                   "LATITUDE", "LONGITUDE", "OBSERVATION.DATE", 
                   "TIME.OBSERVATIONS.STARTED", "DURATION.MINUTES", "EFFORT.DISTANCE.KM",
                   "NUMBER.OBSERVERS", "COMMON.NAME", "SCIENTIFIC.NAME", 
                   "OBSERVATION.COUNT", "PresAbs")
 #Subset and reorder the columns in BirdComplete based on the information
 # in ColumnsToKeep.
BirdComplete <- BirdComplete[, ColumnsToKeep]
 #
#Subset and reorganize the columns in SamplingComplete.  We use
# the "intersect" function to create the needed list of column
# names that are actually present in the SamplingComplete data.frame; 
# thankfully, the "intersect" command appears to preserve the ordering 
# of elements in ColumnsToKeep.
SamplingComplete <- SamplingComplete[, intersect(ColumnsToKeep, names(SamplingComplete))]
 




####################################################################################
################ Create and (below) run function to do zero filling ################
####################################################################################
#
#Because zero-filling will often be a process conducted for data from
# several species of birds, while the initial processing above only
# needs to be done once, it makes sense to wrap the zero-filling
# process within a function, so that each species' zero filling can
# be run repeatedly with just changes in the names of the species
# changed.  Below, we declare the function, which requires 3 input
# objects to be named (there are no defaults!):
#  (1) The English-language name (eBird/Clements version) of the
#       species whose data are to be zero-filled.  For internationalization
#       we probably should use Latin names instead.
#  (2) The name of the data.frame containing the data from the EBD's
#       "bird" table, which provides the non-zero counts.
#  (3) The name of the data.frame containing the data from the EBD's
#       "sampling" table, which provides the record of all checklists
#       needed for inferring zero-value records.
ZeroFillEBD <- function(US.NAME,
                        BirdComplete, 
                        SamplingComplete){
  #Figure out the Latin name for the species of interest, so that
  # this name can be placed into the output.
  SCI.NAME <- unique(BirdComplete[BirdComplete$COMMON.NAME == US.NAME,]$SCIENTIFIC.NAME)
  #There is just one element missing before we can happily zero-fill:
  # a way of adding the "missing" columns to SamplingComplete in order
  # to create a full record for a species for which zero individuals
  # were observed, a record that would exactly match a record from the
  # BirdComplete data.frame.
   #
  #Now we can create a template row of additional material.
  TemplateZeroInfo <- data.frame(US.NAME, 
                                 SCI.NAME, 
                                 0, 
                                 0, 
                                 stringsAsFactors = F)
  names(TemplateZeroInfo) <- c("COMMON.NAME", 
                               "SCIENTIFIC.NAME", 
                               "OBSERVATION.COUNT", 
                               "PresAbs")
   #
  #Create a version of SamplingComplete that adds the columns of
  # information from TemplateZeroInfo such that records of zero
  # birds of the focal species are created, and then tidy up.
  ZeroRecords <- cbind(SamplingComplete, TemplateZeroInfo)
  rm(TemplateZeroInfo)
   #
  #Append the zero records to the actual records of occurrence,
  # and tidy up.
  RealPlusZero <- rbind(BirdComplete[BirdComplete$SCIENTIFIC.NAME == SCI.NAME,], ZeroRecords)
  rm(ZeroRecords)
   #
  ZeroFillCount <- aggregate(x = RealPlusZero$OBSERVATION.COUNT, 
                             by = list(RealPlusZero$SAMPLING.EVENT.IDENTIFIER,
                                       RealPlusZero$COMMON.NAME,
                                       RealPlusZero$SCIENTIFIC.NAME), 
                             FUN = "sum")
  names(ZeroFillCount) <- c("SAMPLING.EVENT.IDENTIFIER", 
                            "COMMON.NAME", 
                            "SCIENTIFIC.NAME", 
                            "OBSERVATION.COUNT")
   #
  ZeroFillPresAbs <- aggregate(x = RealPlusZero$PresAbs, 
                               by = list(RealPlusZero$SAMPLING.EVENT.IDENTIFIER,
                                         RealPlusZero$COMMON.NAME,
                                         RealPlusZero$SCIENTIFIC.NAME), 
                               FUN = "max")
  names(ZeroFillPresAbs) <- c("SAMPLING.EVENT.IDENTIFIER", 
                              "COMMON.NAME", 
                              "SCIENTIFIC.NAME", 
                              "PresAbs")
   #
  rm(RealPlusZero)
   #
  #Merge the zero-filled counts and presence/absence data
  # back with the information in SamplingComplete in order
  # to create the final zero-filled data product.  In the
  # process of merging the bits together, the ordering of
  # the columns is messed up, so we need to reshuffle the
  # columns another time.
  ZeroFilled <- merge(x = SamplingComplete, 
                      y = ZeroFillCount, 
                      by = "SAMPLING.EVENT.IDENTIFIER")
  ZeroFilled <- merge(x = ZeroFilled,
                      y = ZeroFillPresAbs,
                      by = c("SAMPLING.EVENT.IDENTIFIER",  
                             "COMMON.NAME", 
                             "SCIENTIFIC.NAME"))
  ZeroFilled <- ZeroFilled[, ColumnsToKeep]
   #
  return(ZeroFilled)
}



#Here is an example of how this function is used, creating zero-filled data for Plain
# Tyrannulet.
#US.NAME <- "Plain Tyrannulet"
Inezia_inornata <- ZeroFillEBD(US.NAME, 
                             BirdComplete, 
                             SamplingComplete)





####################################################################################
################ Create and (below) run function to "de-duplicate"  ################
################### information from groups of shared checklists ###################
####################################################################################
#
#For many purposes, we need to aggregate the information from groups of shared checklists into becoming a single
# checklist, prior to analyses.  Without doing this we have a problem that the same (or extremely similar) data
# are represented multiple times within our data set, which violates the rather important assumption of 
# independence of samples.  The way that sharing works, it is possible for each checklist within a group to have
# different values for the counts of numbers of individual birds seen: once a checklist is shared, the owner of
# each list in the group can modify these values to match the species and numbers of individuals per species
# that they personally saw.  Actually, the owner of each checklist in a shared group can also alter the values
# for the amount of effort (time and distance travelled) for their own list.  So, we need some logical way of
# creating a single list that well-represents the results of the entire group's efforts.
#I can see three logical methods of collapsing down information from shared checklists that are all reasonably
# logical.  These three alternatives are:
#  (1) choose an arbitrary checklist from each group to use.
#  (2) take the mean values of the counts of birds within each group.
#  (3) select the maximum value (from within each group) to represent the group's combined checklist.
#In the function that we declare below, we use the third of the options listed above.  My reasoning for doing
# this is that when one selects a single arbitrary checklist or takes a mean value, then the effects of variation
# in the NUMBER.OBSERVERS might not be reflected accurately.  Each distinct observer has the potential to see a
# species that no other observer detected, or to see a larger number of individuals of any species than all other
# observers.  The potential for this to happen should increase as the number of observers in a group increases.
# Arbitrarily selecting a single checklist, or taking a mean of what was reported across lists will serve to
# eliminate these higher counts from the data, higher counts that are a legitimate reflection of the real process
# of having higher potential counts for some individual observers.  Anyway, that is roughly my rationale for 
# using maximum values when summarizing information from multiple checklists within a shared group.  I have no clue
# of the extent to which using the three optional approaches would affect anything.
#Note, however, that I have not used this merge-to-max approach for any effort-related variables: COUNT.DURATION,
# EFFORT.DISTANCE.KM, or NUMBER.OBSERVERS.
#The function "MergeGroupCountsToMax" requires only a single input, the name of the data.frame whose data are
# to be collapsed down.  Returned is a data.frame with the identical columns as the input, but with only a single
# row of data for each group.  When this aggregation has been done, the SAMPLING.EVENT.IDENTIFIER value has
# been replaced with the GROUP.IDENTIFIER value, as an indicator that the aggregation has been performed for
# the data in that row.  Probably the most fragile aspect of this function is that it requires that the count
# data be represented both as actual counts (with the column named "OBSERVATION.COUNT"), and as a presence/absence
# variable (named "PresAbs" with a numeric value of zero when no birds of a species were reported, and a value of
# one when at least one individual bird of a species was reported).  The function will fall over and die messily
# if it does not find these two variables named as described.  The names should be correct in the input data,
# as long as these data came from the eBird Basic Dataset (EBD) in it's current (i.e. version "ebd_relFeb-2017")
# format, and if the data were passed through the companion function "ZeroFillEBD" that converts the presence-only
# count data into presence - non-detection data that contains both counts and presence/absence versions thereof.
#This function was created by Wesley Hochachka on 10 February 2017.  PLEASE IGNORE THE WARNING MESSAGES GENERATED
# WHEN RUNNING THIS FUNCTION, AS THEN ONLY INDICATE THAT R IS GENERICALLY CONCERNED ABOUT A POTENTIAL ISSUE THAT
# IS IRRELEVANT IN THIS SPECIFIC CASE...I STILL NEED TO TRAP AND REMOVE THE ERROR MESSAGES FROM OUTPUT.
#
MergeGroupCountsToMax <- function(DataIn){
   #
   #Split the data into the subset of non-shared lists (to which nothing is done) and shared lists whose
   # data need to be appropriately aggregated into a single entity.
   NonShared <- DataIn[DataIn$GROUP.IDENTIFIER == "",]
   Shared <- DataIn[DataIn$GROUP.IDENTIFIER != "",]
   #
   #Create a base version of the information within each shared group by arbitrarily selecting the first checklist
   # is a shared group (i.e. the one with the lowest value for its SAMPLING.EVENT.IDENTIFIER), and stripping off
   # the final two columns that contain the count and presence/absence information.
   Shared <- Shared[order(Shared$SAMPLING.EVENT.IDENTIFIER),]
   SharedBase <- Shared[!duplicated(Shared$GROUP.IDENTIFIER), -(which(names(Shared) %in% c("OBSERVATION.COUNT", "PresAbs")))]
   #
   #Use the "aggregate" function to calculate the maximum count, and the maximum presence/absence value found
   # within each group, using the GROUP.IDENTIFIER variable to form the groups.  Then do some quick renaming
   # of the columns in the output, because the names arbitrarly created by R are pretty uninformative.
   #Note that for calculating the maximum count I had to declare a function within the "aggregate" command
   # because I wanted to specify that we were to remove all missing-value values from processing; if this
   # is not done the presence of a missing value in any shared group will result in R returning "NA" as the
   # maximum value for a group.  This would be inappropriate for our purposes.  Missing-value codes are
   # present in the counts for cases in which an observer reported only that the species was present but 
   # the number of individuals not counted (represented within the eBird database as an "X").  Potentially,
   # some people in a group may have reported an "X" whereas others have provided counts.  To me, it seems 
   # most reasonable to let the counts pass through the aggregation, if any are present, than to produce 
   # an NA in these cases.  If you do not share this opinion, then modify the first "aggregate" statement
   # so that 'FUN = "max"'.
   SharedCount <- aggregate(x = Shared$OBSERVATION.COUNT, 
                            by = list(Shared$GROUP.IDENTIFIER), 
                            FUN = function(OBSERVATION.COUNT){max(OBSERVATION.COUNT, na.rm = T)})
   names(SharedCount) <- c("GROUP.IDENTIFIER", "OBSERVATION.COUNT")
   SharedPresAbs <- aggregate(x = Shared$PresAbs, by = list(Shared$GROUP.IDENTIFIER), FUN = "max")
   names(SharedPresAbs) <- c("GROUP.IDENTIFIER", "PresAbs")
   #
   #Now to the SharedBase data.frame add back in turn the "OBSERVATION.COUNT" and "PresAbs" information
   # that was produced using "aggregate".
   SharedBase <- merge(x = SharedBase, y = SharedCount, by = "GROUP.IDENTIFIER")
   SharedBase <- merge(x = SharedBase, y = SharedPresAbs, by = "GROUP.IDENTIFIER")
   #
   #We need two final clerical steps.  First, because the first "aggregate" function will return 
   # a value of "-Inf" if all of the rows within a shared group have an NA value for a species.  
   # Below we convert these -Inf values back to the missing value code of NA.
   #The second clerical step is to replace the SAMPLING.EVENT.IDENTIFIER values for the
   # records from shared groups with the value for the GROUP.IDENTIFIER as an indicator that
   # data were collapsed down across multiple checklists that each had a unique value for
   # SAMPLING.EVENT.IDENTIFIER.
   SharedBase[SharedBase$OBSERVATION.COUNT == -Inf,]$OBSERVATION.COUNT <- NA
   SharedBase$SAMPLING.EVENT.IDENTIFIER <- SharedBase$GROUP.IDENTIFIER 
   #
   #Return the resultant data, and in the process of doing so recombine the rows from the
   # non-shared and the (now aggregated) shared checklists.
   return(rbind(NonShared, SharedBase))
}

#Now run the de-duplicating.
Inezia_inornata_uniq <-  MergeGroupCountsToMax(Tyrannus_savana)
save("Inezia_inornata_uniq", file = "Inezia_inornata.RData")




