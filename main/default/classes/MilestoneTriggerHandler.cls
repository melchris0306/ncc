/**
 * Created by angelorivera on 10/12/20.
 */

public class MilestoneTriggerHandler {
  /*******************************************************************************
   * @description  handles all after insert events.
   * @param        newMap - Trigger.newMap context variable
   * @revision     10.09.2020 - APRivera - Created
   *******************************************************************************/
  public static void handleAfterInsert(Map<Id, Milestone__c> newMap) {
    processMilestones(null, newMap, 'INSERT');
  }

  /*******************************************************************************
   * @description  handles all after update events.
   * @param        newMap - Trigger.newMap context variable
   * @revision     31.03.2021 - APRivera - Created
   *******************************************************************************/
  public static void handleBeforeUpdate(Map<Id, Milestone__c> newMap) {
    //processMilestones(null, newMap, 'UPDATE');
  }
  /*******************************************************************************
   * @description  handles all after update events.
   * @param        oldMap - Trigger.oldMap context variable
   * @param        newMap - Trigger.newMap context variable
   * @revision     31.03.2021 - APRivera - Created
   *******************************************************************************/
  public static void handleAfterUpdate(
          Map<Id, Milestone__c> oldMap,
          Map<Id, Milestone__c> newMap
  ) {
    processMilestones(oldMap, newMap, 'UPDATE');
  }

  /*******************************************************************************
   * @description  handles all after delete events.
   * @param        oldMap - Trigger.oldMap context variable
   * @revision     10.09.2020 - APRivera - Created
   *******************************************************************************/
  public static void handleBeforeDelete(Map<Id, Milestone__c> oldMap) {
    processMilestones(oldMap, null, 'DELETE');
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         10.10.2020
   * @description  Process Milestones
   * @param        oldMap - map of the old records
   * @param        newMap - map of the new records
   * @param        evt - trigger event
   * @revision     10.10.2020 - APRivera - Created
   * @revision     24.12.2021 - Dbrinas - Updated/added Parent Milestone and Display field
   *******************************************************************************/
  public static void processMilestones(Map<Id, Milestone__c> oldMap, Map<Id, Milestone__c> newMap, String evt ) {
    List<Milestone__c> lstMilestones = new List<Milestone__c>();
    Set<Id> setJourneyIds = new Set<Id>();
    Set<Id> setMilestoneIds = new Set<Id>();
    Set<Decimal> setSortOrder = new Set<Decimal>();

    if (evt == 'INSERT') {
      for (Milestone__c mStones : newMap.values()) {
        if (mStones.Journey__c != null) {
          setJourneyIds.add(mStones.Journey__c);
          lstMilestones.add(mStones);
          setMilestoneIds.add(mStones.Id);
        }
      }
      if (!setJourneyIds.isEmpty()) JourneyParticipantServices.processNewMilestones(setJourneyIds,setMilestoneIds);
    } else if (evt == 'DELETE') {
      for (Milestone__c mStones : oldMap.values()) {
        if (mStones.Journey__c != null) {
          System.debug('!@#$ mStones ' + mStones);
          setJourneyIds.add(mStones.Journey__c);
          lstMilestones.add(mStones);
          setSortOrder.add(mStones.Sort_Order__c);
        }
      }
      if (!setJourneyIds.isEmpty()) {
        BatchDeleteParticipantMilestones batchObj = new  BatchDeleteParticipantMilestones();
        batchObj.setJourneyIds = setJourneyIds;
        batchObj.lstMilestones = lstMilestones;
        batchObj.setSortOrder = setSortOrder;
        Id batchProcessId = Database.executeBatch(batchObj,40);
      }
      //JourneyParticipantServices.processDeletedMilestones(setJourneyIds,lstMilestones);
    } else if (evt == 'UPDATE') {
      for (Milestone__c mStones : newMap.values()) {
        if (oldMap != null) {
          Milestone__c mStonesOld = oldMap.get(mStones.Id);
          if (mStones.Journey__c != null) {
            if (
                    mStones.RecordTypeId != mStonesOld.RecordTypeId ||
                            mStones.Sort_Order__c != mStonesOld.Sort_Order__c ||
                            mStones.Parent__c != mStonesOld.Parent__c ||
                            mStones.Is_Active__c != mStonesOld.Is_Active__c ||
                            mStones.Description__c != mStonesOld.Description__c ||
                            mStones.Start_Date__c != mStonesOld.Start_Date__c ||
                            mStones.End_Date__c != mStonesOld.End_Date__c ||
                            mStones.Milestone_URL__c != mStonesOld.Milestone_URL__c ||
                            mStones.Parent_Milestone__c != mStonesOld.Parent_Milestone__c || //Added by DinoBrinas [CCN973] Dec232021
                            mStones.Display_In_Dashboard__c != mStonesOld.Display_In_Dashboard__c //Added by DinoBrinas [CCN973] Dec232021
                    ) {
              setJourneyIds.add(mStones.Journey__c);
              lstMilestones.add(mStones);
            }
          }
        } else {
          setJourneyIds.add(mStones.Journey__c);
          lstMilestones.add(mStones);
        }
      }
      if(!setJourneyIds.isEmpty()) JourneyParticipantServices.processUpdatedMilestones( setJourneyIds, lstMilestones );
    }
  }
}