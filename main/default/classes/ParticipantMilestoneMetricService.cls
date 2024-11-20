/*******************************************************************************************
 * @name: ParticipantMilestoneMetricService
 * @author: DinoBrinas
 * @created: 14-01-2022
 * @description: This is used for Aura button, then run the batch
 * 
 * Changes (version)
 * -------------------------------------------------------------------------------------------
 *               No.     Date(dd-mm-yyy) Author                  Description
 *               ----    ---------       --------------------    -----------------------------
 * @version      1.0     14-01-2022      DinoBrinas              Initial version.
*********************************************************************************************/
public with sharing class ParticipantMilestoneMetricService {
    public ParticipantMilestoneMetricService() {

    }
    /*******************************************************************************
     * @author       DinoBrinas 
     * @date         14-01-2022
     * @description  This is used for Aura button, then run the batch
     * @param        journeyId - journey Id
     * @return       strResult
     * @revision     15.10.2020 - APRivera - Created
     *******************************************************************************/
    @AuraEnabled
    public static String generateParticipantMilestonMetric(Id journeyId) {
        Set<Id> setUserJourneyId = new Set<Id>();
        Set<Id> setJourneyIds = new Set<Id>();
        Map<Id, Map<String, List<String>>> mapMilestoneMetricByTypeByJourneyId = new Map<Id, Map<String, List<String>>>();
        System.debug(' @@@@@ journeyId >>>>> ' + journeyId);
        
        setJourneyIds.add(journeyId);

        Map<Id, Journey__c> mapJourneysByIds = JourneyParticipantServices.getJourney(setJourneyIds);

        mapMilestoneMetricByTypeByJourneyId = JourneyParticipantServices.getMilestoneMetricsByJourneyId(mapJourneysByIds);
        
        System.debug('!@# mapJourneysByIds' + mapJourneysByIds.size());
        System.debug('!@# mapMilestoneMetricByTypeByJourneyId' + mapMilestoneMetricByTypeByJourneyId.size());

        Set<Id> setIds = new Set<Id>();
        setIds.add(journeyId);
        // Run the Batch here.
        BatchCreateParticipantMilestoneMetrics  batchObj = new  BatchCreateParticipantMilestoneMetrics();
        batchObj.setJourneyIds = setJourneyIds;
        batchObj.mapMilestoneMetricByTypeByJourneyId = mapMilestoneMetricByTypeByJourneyId;

        Id batchProcessId = Database.executeBatch(batchObj,20);
        System.debug(' @@@@@ setIds >>>> ' + setIds);
        System.debug(' @@@@@ batchProcessId >>>> ' + batchProcessId );
        return '';
    }
}