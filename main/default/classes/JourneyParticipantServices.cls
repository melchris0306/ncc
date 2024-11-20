/**
 * @description Service Class for Journey_Participant__c
 * @revision
 *           10.09.2020 - APRivera - Initial Creation
 *           12.24.2020 - APRivera - CCN-1086 - Fixed milestone data volume issue
 *           08.02.2022 - APRivera - CCN-1108/CCN-1109 Enhancement
 *           07.08.2022 - APRivera - CCN-1848/CCN-1856 Enhancement
 *           07.13.2022 - APRivera - CCN-1843 Enhancement
 *           15.12.2023 - APRivera - Added new milestone types (Attestation and Information)
 **/

public with sharing class JourneyParticipantServices {
  public static JourneyCommunitySettings__c UserJourneyCommunitySettings {
    get {
      if (UserJourneyCommunitySettings == null)
        UserJourneyCommunitySettings = JourneyCommunitySettings__c.getOrgDefaults();
      return UserJourneyCommunitySettings;
    }
    set;
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         11.09.2020
   * @description  Returns the Community URL
   * @param        communityName - List of User Milestones to be processed
   * @return       siteUrl - URL of the Community
   * @revision     11.09.2020 - APRivera - Created
   *******************************************************************************/
  public static String getCommunityURL(String communityName) {
    if (!Test.isRunningTest()) {
      Network myNetwork = [SELECT Id FROM Network WHERE Name = :communityName];
      ConnectApi.Community myCommunity = ConnectApi.Communities.getCommunity(
        myNetwork.Id
      );
      return myCommunity.siteUrl;
    } else {
      return 'some random url';
    }
  }


  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         11.09.2020
   * @description  Returns the Community URL
   * @param        journeyId - Journey Record Id
   * @return       strResult - response
   * @revision     11.09.2020 - APRivera - Created
   * @revision     10.06.2021 - APRivera - Added field on SOQL
   * @revision     08.02.2022 - APRivera - CCN-1108/CCN-1109 Enhancement
   *******************************************************************************/
  @AuraEnabled
  public static String generateMilestones(Id journeyId) {
    String strResult = '';

    if (journeyId != null) {
      Journey__c journey = [ SELECT Id, Event__c, Event__r.Name, Status__c, Campaign__c,
                            (SELECT Id, Name, Related_RecordId__c FROM Milestones__r)
                            FROM Journey__c
                            WHERE Id = :journeyId];

      if (journey.Campaign__c != null) {
        List<Milestone__c> lstMilestones = new List<Milestone__c>();
        List<Event__c> lstEvents = new List<Event__c>();
        List<Quick_Check__c> lstQuickChecks = new List<Quick_Check__c>();
        List<Survey__c> lstSurveys = new List<Survey__c>();
        List<Communication__c> lstCommunications = new List<Communication__c>();
        List<Session__c> lstSessions = new List<Session__c>();
        Set<Id> setExistingIds = new Set<Id>();
        Set<Id> setEventIds = new Set<Id>();
        Set<Id> setQuickCheckIds = new Set<Id>();
        Set<Id> setSurveyIds = new Set<Id>();

        for(Adhoc_Journey_Assignment__c adhocJourney : [SELECT Id, Journey__c, Survey__c, Event__c, Quick_Check__c
                                                        FROM Adhoc_Journey_Assignment__c
                                                        WHERE Journey__c =: journey.Id]){
          setEventIds.add(adhocJourney.Event__c);
          setSurveyIds.add(adhocJourney.Survey__c);
          setQuickCheckIds.add(adhocJourney.Quick_Check__c);
        }


        for (Event__c evtRecord : [ SELECT Id, Name, Campaign__c, Event_Page_URL__c, Event_Id__c, Start_Date_Time__c, End_Date_Time__c
                                    FROM Event__c
                                    WHERE (Campaign__c = :journey.Campaign__c AND Journey__c = :journey.Id AND Milestone__c = TRUE)
                                    OR (Id IN: setEventIds AND Milestone__c = TRUE)]) {
          setEventIds.add(evtRecord.Id);
          lstEvents.add(evtRecord);
        }

        for (Quick_Check__c quickCheck : [ SELECT Id, Name, Add_Milestone_to_Journey__c, Quick_Check_Start_Date__c, Quick_Check_End_Date__c, Quick_Check_Style__c, Active__c
                                    FROM Quick_Check__c
                                    WHERE Id IN: setQuickCheckIds AND Add_Milestone_to_Journey__c = TRUE]) {
          setQuickCheckIds.add(quickCheck.Id);
          lstQuickChecks.add(quickCheck);
        }

        for(Session__c session : [SELECT Id, Name, Event_Id__c, IsActive__c, Start_Date_Time__c, End_Date_Time__c, Catch_up__c, Catchup_Start_Date__c, Catchup_End_Date__c
                                    FROM Session__c
                                    WHERE Milestone__c = TRUE
                                    AND IsActive__c = TRUE
                                    AND Event__c IN: setEventIds]){
          lstSessions.add(session);
          setExistingIds.add(session.Id);
        }

        for (Communication__c comms : [ SELECT Id, Journey__c, Campaign__c, Name
                                      FROM Communication__c
                                      WHERE Journey__c = :journey.Id
                                      AND Campaign__c = :journey.Campaign__c
                                      AND Milestone__c = TRUE]) {
          lstCommunications.add(comms);
        }

        for (Survey__c surv : [SELECT Id, Survey_Campaign__c, Journey__c, Name, Event__c, Standalone_Survey_URL__c,
                                Event_Id__c, Journey_Milestone_End_Date__c, Journey_Milestone_Start_Date__c
                                FROM Survey__c
                                WHERE (Survey_Campaign__c = :journey.Campaign__c AND Journey__c = :journey.Id AND Milestone__c = TRUE) // standalone survey
                                OR (Event__c IN: setEventIds AND Milestone__c = TRUE AND Journey__c = :journey.Id)                     // survey of the events
                                OR (Id IN: setSurveyIds AND Milestone__c = TRUE)                                                       // survey from Adhoc journey assignment
        ]) {
          if(!setExistingIds.contains(surv.Id)) lstSurveys.add(surv);
        }

        if (!lstSurveys.isEmpty()) {
          createMilestones(lstMilestones, journey, lstSurveys);
        }

        if (!lstCommunications.isEmpty()) {
          createMilestones(lstMilestones, journey, lstCommunications);
        }

        if (!lstEvents.isEmpty()) {
          createMilestones(lstMilestones, journey, lstEvents);
        }

        if (!lstSessions.isEmpty()) {
          createMilestones(lstMilestones, journey, lstSessions);
        }

        if (!lstQuickChecks.isEmpty()) {
          createMilestones(lstMilestones, journey, lstQuickChecks);
        }

        if (!lstMilestones.isEmpty()) {
          Database.insert(lstMilestones);
          strResult = lstMilestones.size() + ' milestones added to the journey.';
        } else {
          strResult = 'No new milestones to be added.';
        }
      } else {
        strResult = 'Make sure that a campaign is linked to the journey before adding milestones.';
      }
    }

    return strResult;
  }
	/*******************************************************************************
   * @author       Mel Mallorca
   * @date         03.10.2024
   * @description  Get All Quick Checks
   * @param        journey  record
   *******************************************************************************/
    public static Map<Id, List<Quick_Check_Question__c>> getJourneyQuickCheckQuestions(Id strJourneyId){
        Map<Id, List<Quick_Check_Question__c>> qcqMap = new Map<Id, List<Quick_Check_Question__c>>();
        
        List<Journey_Participant__c> jpList = [Select Id, Journey__c From Journey_Participant__c Where Id =: strJourneyId];
        Set<Id> journeySet = new Set<Id>();
        for(Journey_Participant__c jp : jpList){
            journeySet.add(jp.Journey__c);
        }
        List<Milestone__c> milestoneList = [SELECT Id, RecordTypeId, RecordType.Name, Name, Sort_Order__c, Description__c,Journey__c, Milestone_URL__c, Is_Active__c,
                                            Related_RecordId__c, Quick_Check_Begin_Button_Text__c, Add_Quick_Check_Begin_Button__c,Type__c, Checkpoint__c, Parent__c, Start_Date__c, End_Date__c, Parent_Milestone__c, Display_In_Dashboard__c
                                            FROM Milestone__c WHERE Is_Active__c = TRUE AND Journey__c IN:journeySet AND Related_RecordId__c != null
                                            ORDER BY Sort_Order__c ASC];
        //system.assertEquals(milestoneList.size(), null);
        Set<Id> quickCheckSet = new Set<Id>();
        Map<Id, Id> milestoneQuickCheckMap = new Map<Id, Id>();
        Map<Id, Id> quickCheckMilestoneMap = new Map<Id, Id>();
        for(Milestone__c m : milestoneList){
            quickCheckSet.add(m.Related_RecordId__c);
            milestoneQuickCheckMap.put(m.Id, m.Related_RecordId__c);
            quickCheckMilestoneMap.put(m.Related_RecordId__c, m.Id);
        }
        
        List<Quick_Check__c> qcList = [Select Id, Active__c From Quick_Check__c Where Id IN: quickCheckSet];
        
        //Set<Id> questionIds = new Set<Id>();
		Map<Id, Id> quickCheckQuestionsMap = new Map<Id, Id>();
             
        List<Quick_Check_Question__c> qcqList = [Select Id, Quick_Check__c, Answers__c, Check_Answers__c, Completion_Message__c,
                                                 Correct_Answer_s__c, Correct_Answer_Message__c, Incorrect_Answer_Message__c, 
                                                 Question__c, Question_Type__c, Required_Question__c, Sort_Order__c
                                                 From Quick_Check_Question__c Where Quick_Check__c IN:qcList
                                                 Order by Sort_Order__c];
        
        for(Quick_Check_Question__c qcq: qcqList){
            if(qcqMap.containsKey(milestoneQuickCheckMap.get(quickCheckMilestoneMap.get(qcq.Quick_Check__c)))){
                qcqMap.get(milestoneQuickCheckMap.get(quickCheckMilestoneMap.get(qcq.Quick_Check__c))).add(qcq);
            }
            else{
                qcqMap.put(milestoneQuickCheckMap.get(quickCheckMilestoneMap.get(qcq.Quick_Check__c)), new List<Quick_Check_Question__c> {qcq});
            }
        }   
        
        return qcqMap;
    }
    
    
    
    
    
    
    
    
  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         07.10.2020
   * @description  Generates New milestones
   * @param        lstMilestones list of user milestones to be added
   * @param        journey Journey record
   * @param        lstSObjectsType list of SObjects (Campaign, Survey or Communication)
   * @revision     07.10.2020 - APRivera - Created
   * @revision     07.10.2020 - APRivera - 00002321 - Added automation on Milestone URL
   *******************************************************************************/
  public static void createMilestones(List<Milestone__c> lstMilestones,Journey__c journey, List<SObject> lstSObjectsType) {
    Id recordTypeId = Schema.SObjectType.Milestone__c.getRecordTypeInfosByDeveloperName().get('Milestone').getRecordTypeId();
    List<SObject> lstSobjects = (List<SObject>) lstSObjectsType;
    Set<String> setMilestoneName = new Set<String>();
    String strJourneyCommunityURL = getCommunityURL(
            UserJourneyCommunitySettings.Community_Name__c
    );

    for (Milestone__c m : journey.Milestones__r) {
      setMilestoneName.add(m.Related_RecordId__c);
    }

    String packageNamespace = String.isNotBlank(FlsUtils.prefix) ? FlsUtils.prefix : ''; // Added for Namespace Issue Fixes - Jayson Labnao September222022
    for (SObject sObj : lstSobjects) {
      Milestone__c milestone = new Milestone__c();
      if (sObj.getSObjectType() == Survey__c.getSObjectType()) {
        milestone.Type__c = 'Survey';
        if((String) sObj.get(packageNamespace + 'Event__c') != null){ // Added for Namespace Issue Fixes - Jayson Labnao September222022
          milestone.Milestone_URL__c = strJourneyCommunityURL + '/s/survey?id=' + (String) sObj.get(packageNamespace + 'Event_Id__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
        }else{
          milestone.Milestone_URL__c = (String) sObj.get(packageNamespace + 'Standalone_Survey_URL__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
        }
        milestone.Start_Date__c = (Date)sObj.get(packageNamespace + 'Journey_Milestone_Start_Date__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
        milestone.End_Date__c = (Date)sObj.get(packageNamespace + 'Journey_Milestone_End_Date__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
      } else if (sObj.getSObjectType() == Event__c.getSObjectType()) {
        milestone.Type__c = 'Event';
        milestone.Milestone_URL__c = (String) sObj.get(packageNamespace + 'Event_Page_URL__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
        Datetime startDt = (Datetime)sObj.get(packageNamespace + 'Start_Date_Time__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
        Datetime endDt = (Datetime)sObj.get(packageNamespace + 'End_Date_Time__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
        milestone.Start_Date__c = startDt.date();
        milestone.End_Date__c = endDt.date();
      } else if (sObj.getSObjectType() == Session__c.getSObjectType()) {
        milestone.Type__c = 'Event';
        milestone.Milestone_URL__c = strJourneyCommunityURL + '/s/sessions?id=' + (String) sObj.get(packageNamespace + 'Event_Id__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
        Datetime startDt = (Datetime)sObj.get(packageNamespace + 'Start_Date_Time__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
        Datetime endDt = (Datetime)sObj.get(packageNamespace + 'End_Date_Time__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
        milestone.Start_Date__c = startDt.date();
        milestone.End_Date__c = endDt.date();
        Datetime catchUpStartDt = (Datetime)sObj.get(packageNamespace + 'Catchup_Start_Date__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
        Datetime catchUpEndDt = (Datetime)sObj.get(packageNamespace + 'Catchup_End_Date__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
        milestone.Session_Catch_Up_Start_Date__c = catchUpStartDt;
        milestone.Session_Catch_Up_End_Date__c = catchUpEndDt;
          milestone.Catch_Up_Completion_Button__c = (Boolean) sObj.get(packageNamespace + 'Catch_up__c'); // Added for Namespace Issue Fixes - Jayson Labnao September222022
      } else if (sObj.getSObjectType() == Communication__c.getSObjectType()) {
        milestone.Type__c = 'Communication';
      } else if(sObj.getSObjectType() == Quick_Check__c.getSObjectType()){
        milestone.Type__c = 'Quick Check';
        milestone.Start_Date__c = (Date)sObj.get(packageNamespace + 'Quick_Check_Start_Date__c');
        milestone.End_Date__c = (Date)sObj.get(packageNamespace + 'Quick_Check_End_Date__c');
      }

      milestone.RecordTypeId = recordTypeId;
      milestone.Name = (String) sObj.get('Name');
      milestone.Related_RecordId__c = sObj.Id;
      milestone.Journey__c = journey.Id;
      milestone.Sort_Order__c = journey.Milestones__r.size() + lstMilestones.size() + 1;
      if(!setMilestoneName.contains((String) sObj.get('Id'))) lstMilestones.add(milestone);
    }
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         15.10.2020
   * @description  Logic that fires when new Milestones are created
   * @param        setJourneyIds set of journey ids
   * @param        setMilestoneIds List of milestones
   * @revision     15.10.2020 - APRivera - Created
   *******************************************************************************/
  @Future
  public static void processNewMilestones( Set<Id> setJourneyIds, Set<Id> setMilestoneIds ) {
    List<Participant_Milestone__c> lstUserMilestones = new List<Participant_Milestone__c>();
    List<Journey_Participant__c> lstJourneyParticipants = new List<Journey_Participant__c>();
    Map<Id, List<Journey_Participant__c>> mapJourneysByIds = new Map<Id, List<Journey_Participant__c>>();

    List<Milestone__c> lstMilestones = new List<Milestone__c>();
    lstMilestones = [SELECT Id, RecordTypeId, Type__c, Parent__c, Description__c, Sort_Order__c, Milestone_URL__c,
            Start_Date__c, End_Date__c, Parent_Milestone__c, Display_In_Dashboard__c
                    FROM Milestone__c WHERE Id IN: setMilestoneIds];
    mapJourneysByIds = getJourneyParticipantsByJourneyIds(setJourneyIds);

    for (Id jId : setJourneyIds) {
      if(mapJourneysByIds.containsKey(jId)){
        // check if journey has exiting journey participants
        if (!mapJourneysByIds.get(jId).isEmpty()) {
          lstJourneyParticipants.addAll(mapJourneysByIds.get(jId));

          // if yes, insert new user milestones to these journey participants
          if (!lstJourneyParticipants.isEmpty()) {
            for (Journey_Participant__c uj : lstJourneyParticipants) {
              createUserMilestones(lstMilestones, uj, lstUserMilestones);
            }
            try {
              if (!lstUserMilestones.isEmpty()) Database.insert(lstUserMilestones);
            } catch (Exception ex) {
              System.debug(LoggingLevel.DEBUG,'!@# ERROR IN INSERT: ' + ex.getMessage());
            }
          }
        }
      }
    }
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         31.03.2021
   * @description  Logic that fires when new Milestones are created
   * @param        setJourneyIds set of journey ids
   * @param        lstMilestones List of milestones
   * @revision     15.10.2020 - APRivera - Created
   *******************************************************************************/
  public static void processUpdatedMilestones(Set<Id> setJourneyIds,List<Milestone__c> lstMilestones) {
    Id milestoneRecordTypeId = Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get('Milestone').getRecordTypeId();
    List<Journey_Participant__c> lstJourneyParticipants = new List<Journey_Participant__c>();

    Set<Id> setMilestoneIds = new Set<Id>();
    for (Milestone__c m : lstMilestones) {
      setMilestoneIds.add(m.Id);
    }

    Map<Id, List<Journey_Participant__c>> mapJourneysByIds = new Map<Id, List<Journey_Participant__c>>();
    mapJourneysByIds = getJourneyParticipantsByJourneyIds(setJourneyIds);

    Map<Id, List<Participant_Milestone__c>> mapParticipantMilestonesByParticipantIds = new Map<Id, List<Participant_Milestone__c>>();
    mapParticipantMilestonesByParticipantIds = getParticipantsWithMilestones(setJourneyIds,setMilestoneIds);

    List<Participant_Milestone__c> lstParticipantMilestones = new List<Participant_Milestone__c>();
    List<Milestone__c> lstMilestonesToUpdate = new List<Milestone__c>();
    Set<Id> setUserJourneyId = new Set<Id>();
    Set<Id> setParticipantMilestoneIds = new Set<Id>();

    for (Milestone__c m : lstMilestones) {
      Milestone__c tempMilestone = new Milestone__c();
      if (m.RecordTypeId != milestoneRecordTypeId) {
        //if recordtype != Milestone
        // Updates the parent Checkpoint to null
        tempMilestone.Id = m.Id;
        tempMilestone.Parent__c = null;
        lstMilestonesToUpdate.add(tempMilestone);
      }

      for (Id jId : setJourneyIds) {
        if(mapJourneysByIds.containsKey(jId)){
          // check if journey has exiting journey participants
          if (!mapJourneysByIds.get(jId).isEmpty()) {
            lstJourneyParticipants.addAll(mapJourneysByIds.get(jId));
            // iterate over each journey participant
            if (!lstJourneyParticipants.isEmpty()) {

              for (Journey_Participant__c jp : lstJourneyParticipants) {
                if(mapParticipantMilestonesByParticipantIds.containsKey(jp.Id)){
                  for (Participant_Milestone__c pm : mapParticipantMilestonesByParticipantIds.get(jp.Id)) {
                    if (pm.Milestone__c == m.Id) {
                      pm.Sort_Order__c = m.Sort_Order__c;
                      pm.Is_Active__c = m.Is_Active__c;
                      pm.Description__c = m.Description__c;
                      pm.Milestone_URL__c = m.Milestone_URL__c;
                      pm.Start_Date__c = m.Start_Date__c;
                      pm.End_Date__c = m.End_Date__c;
                      pm.Parent_Milestone__c = m.Parent_Milestone__c;
                      pm.Display_In_Dashboard__c = m.Display_In_Dashboard__c;

                      if (m.RecordTypeId == milestoneRecordTypeId) {
                        //if recordtype = Milestone
                        pm.Type__c = m.Type__c;
                        pm.Checkpoint__c = false;
                        pm.Checkpoint_Name__c = m.Parent__c;
                        setUserJourneyId.add(pm.Journey__c);
                      } else {
                        pm.Type__c = 'Checkpoint';
                        pm.Checkpoint__c = true;
                        pm.Checkpoint_Name__c = null;
                        setParticipantMilestoneIds.add(pm.Id);
                      }
                      lstParticipantMilestones.add(pm);
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    try {
      if (!lstParticipantMilestones.isEmpty()) Database.update(lstParticipantMilestones);
      if (!lstMilestonesToUpdate.isEmpty()) Database.update(lstMilestonesToUpdate);
    } catch (Exception ex) {
      System.debug(LoggingLevel.DEBUG,'!@# ERROR IN UPDATE: ' + ex.getMessage());
    }

    try {
      if (!setParticipantMilestoneIds.isEmpty()) {
        List<Participant_Milestone_Metric__c> lstParticipantMetrics = new List<Participant_Milestone_Metric__c>();
        lstParticipantMetrics = [ SELECT Id FROM Participant_Milestone_Metric__c WHERE Milestone__c IN :setParticipantMilestoneIds];
        if(!lstParticipantMetrics.isEmpty()) Database.delete(lstParticipantMetrics);
      }
    } catch (Exception ex) {
      System.debug( LoggingLevel.DEBUG, '!@# ERROR IN DELETE: ' + ex.getMessage() );
    }
  }



  /*******************************************************************************
   * @author       APR
   * @date         12-07-2022
   * @description  Wrapper class for Journey Participant
   * @param       journeyId - Journey Id
   * @return      JourneyEventsWrapper
   * @revision    12-07-2022 - APRivera - Created for CCN-1843 Enhancement
   *******************************************************************************/
  @AuraEnabled
  public static JourneyEventsWrapper retrieveJourneyEvents(Id journeyId) {
    JourneyEventsWrapper journeyWrapper = new JourneyEventsWrapper();
    journeyWrapper.listJourneyEvents = new List<EventWrapper>();
    Set<Id> setEventIds = new Set<Id>();
    journeyWrapper.strMessage = '';

    if (journeyId != null) {
      Journey__c journey = [SELECT Id,Status__c FROM Journey__c WHERE Id = :journeyId];

      if (journey.Status__c == 'Approved') {
        for(Adhoc_Journey_Assignment__c aja : [SELECT Id, Journey__c, Event__c, Event__r.Name
                                              FROM Adhoc_Journey_Assignment__c
                                              WHERE Journey__c =: journey.Id
                                              AND Event__c != NULL
                                              ORDER BY Event__r.Name]){
          if(!setEventIds.contains(aja.Event__c)){
            EventWrapper evt = new EventWrapper();
            evt.eventId = aja.Event__c;
            evt.eventName = aja.Event__r.Name;
            journeyWrapper.listJourneyEvents.add(evt);
            setEventIds.add(aja.Event__c);
          }
        }
      }
      else {
        journeyWrapper.strMessage = 'You can only add journey participants on Approved Journey.';
      }
    }

    return journeyWrapper;
  }


  /*******************************************************************************
   * @author       APR
   * @date         08-07-2022
   * @description  Wrapper class for Journey Participant
   *******************************************************************************/
    public class JourneyEventsWrapper {
      @AuraEnabled public  List<EventWrapper> listJourneyEvents {get; set;}
      @AuraEnabled public String strMessage {get; set;}
    }


  /*******************************************************************************
   * @author       APR
   * @date         08-07-2022
   * @description  Wrapper class for Event
   *******************************************************************************/
    public class EventWrapper {
      @AuraEnabled public Id eventId {get; set;}
      @AuraEnabled public String eventName {get; set;}

    }


  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         13-07-2022
   * @description  method used in CreateJourneyParticipants Aura component
   * @param        journeyId - Journey Id
   * @param        ListEventIds - List of Journey Ids
   * @return       strResult
   * @revision     13-07-2022 - APRivera - Created for CCN-1843 Enhancement
   *******************************************************************************/
  @AuraEnabled
  public static String createJourneyParticipants(Id journeyId, List<Id> ListEventIds) {
    String strResult = '';

    if(!ListEventIds.isEmpty()){
      Set<Id> setEventIds = new Set<Id>();
      Set<Id> setContactIds = new Set<Id>();
      Set<Id> setContactIdsWithUserJourneys = new Set<Id>();

      for(Id evtId : ListEventIds){
        setEventIds.add(evtId);
      }

      Journey__c journey = [SELECT Id, (SELECT Contact__c FROM Journey_Participants__r)
                            FROM Journey__c
                            WHERE Id = :journeyId];

      // get the existing contacts that are journey participants already
      if (!journey.Journey_Participants__r.isEmpty()) {
        for (Journey_Participant__c jp : journey.Journey_Participants__r) {
          setContactIdsWithUserJourneys.add(jp.Contact__c);
        }
      }

      //get Participants of Events
      for (Participant__c cm : [SELECT Id, Event__c, Member_Contact__c FROM Participant__c
                                WHERE Event__c IN :setEventIds AND Member_Contact__c != NULL]){
        if (!setContactIdsWithUserJourneys.contains(cm.Member_Contact__c)
                && !setContactIds.contains(cm.Member_Contact__c)) {
          setContactIds.add(cm.Member_Contact__c);
        }
      }

      if (!setContactIds.isEmpty()) {
        List<Journey_Participant__c> lstJourneyParticipants = new List<Journey_Participant__c>();
        // generate Journey Participant records
        generateJourneyParticipants(setContactIds,lstJourneyParticipants,journeyId);
        try{
          if (!lstJourneyParticipants.isEmpty()) {

            // todo update journey flag that process is happening in the backend
            //journey.Backend_Process_Running__c = true;
            Database.update(journey);

            Database.insert(lstJourneyParticipants);
            strResult = lstJourneyParticipants.size() +' contacts added as journey participants.';
            System.debug(LoggingLevel.DEBUG,'!@# lstJourneyParticipants: ' + lstJourneyParticipants.size());
          }
        }
        catch (Exception ex) {
          System.debug(LoggingLevel.DEBUG,'!@# ERROR IN INSERTING Journey participants: ' + ex.getMessage());
        }
      }
      else {
        strResult = ' No New Participant/Contact to be added as new Journey participants.';
      }
    }
    return strResult;
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         03.10.2020
   * @description  Generates User Journey participants
   * @param        setContactIds -Set of contact ids
   * @param        lstJourneyParticipants - List of Journey participants
   * @param        journeyId - journey Id
   * @revision     03.10.2020 - APRivera - Created
   *******************************************************************************/
  public static void generateJourneyParticipants(Set<Id> setContactIds,List<Journey_Participant__c> lstJourneyParticipants,Id journeyId) {
    for (Id conId : setContactIds) {
      Journey_Participant__c jp = new Journey_Participant__c(Contact__c = conId,Journey__c = journeyId);
      lstJourneyParticipants.add(jp);
    }
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         10.09.2020
   * @description  Process User Journeys to be inserted.
   *               Copies values from Journey Template.
   *               Inserts User Milestones from Journey Template - Milestones.
   * @param        lstUserJourneys - List of User Journeys to be processed
   * @param        setJourneyIds - Journey template set of Ids
   * @param        setIds - Journey Participants set of Ids
   * @revision     10.09.2020 - APRivera - Created
   *******************************************************************************/
  public static void processNewUserJourneys(List<Journey_Participant__c> lstUserJourneys,Set<Id> setJourneyIds, Set<Id> setIds) {
    Map<Id, Journey__c> mapJourneysByIds = getJourney(setJourneyIds);

    if (!mapJourneysByIds.isEmpty()) {
      //retrieves the User Journey Community URL
      String strJourneyCommunityURL = getCommunityURL( UserJourneyCommunitySettings.Community_Name__c );

      if (strJourneyCommunityURL != null) {
        Map<Id, List<Milestone__c>> mapMilestonesByJourneyIds = new Map<Id, List<Milestone__c>>();
        mapMilestonesByJourneyIds = getJourneyMilestones(setJourneyIds);

          if(!lstUserJourneys.isEmpty()){
            BatchCreateParticipantMilestones batchObj = new  BatchCreateParticipantMilestones();
            batchObj.setIds = setIds;
            batchObj.mapJourneysByIds = mapJourneysByIds;
            batchObj.mapMilestonesByJourneyIds = mapMilestonesByJourneyIds;
            batchObj.strJourneyCommunityURL = strJourneyCommunityURL;
            Id batchProcessId = Database.executeBatch(batchObj,10);
          }
      } else {
        System.debug( LoggingLevel.DEBUG,'!@# Missing or invalid UserJourneyCommunitySetting__c.');
      }
    }
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         10.09.2020
   * @description  Process System generated User Milestones
   * @param        lstUserMilestones - List of User Milestones to be processed
   * @param        setUserJourneyId - Set of User Journey Ids
   * @revision     10.09.2020 - APRivera - Created
   *******************************************************************************/
  public static void processNewUserMilestones(List<Participant_Milestone__c> lstUserMilestones,Set<Id> setUserJourneyId) {
    Map<Id, Id> mapJourneyIdsByUserJourneyIds = getJourneyIds(setUserJourneyId);
    Set<Id> setJourneyIds = new Set<Id>();
    for (Id jId : mapJourneyIdsByUserJourneyIds.values()) {
      setJourneyIds.add(jId);
    }

    if (!lstUserMilestones.isEmpty()) {
      //retrieves Journey records
      Map<Id, Journey__c> mapJourneysByIds = getJourney(setJourneyIds);

      //get the milestone metrics of each journey, mapped by Milestone Type
      Map<Id, Map<String, List<String>>> mapMilestoneMetricByTypeByJourneyId = new Map<Id, Map<String, List<String>>>();
      mapMilestoneMetricByTypeByJourneyId = getMilestoneMetricsByJourneyId(mapJourneysByIds);
      //Creates User Milestone Metric to be inserted
      Set<Id> setParticipantMilestones = new Set<Id>();
      for(Participant_Milestone__c pm : lstUserMilestones){
        setParticipantMilestones.add(pm.Id);
      }

      if(Test.isRunningTest()){
        //Creates User Milestone Metric to be inserted
        List<Participant_Milestone_Metric__c> lstUserMilestoneMetrics = new List<Participant_Milestone_Metric__c>();
        createUserMilestoneMetric(lstUserMilestoneMetrics,lstUserMilestones,mapJourneyIdsByUserJourneyIds,mapMilestoneMetricByTypeByJourneyId);

        if (!lstUserMilestoneMetrics.isEmpty()) {
          Database.insert(lstUserMilestoneMetrics);
        }
      }
    }
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         20.09.2020
   * @description  creates User Milestone Metric
   * @param        mapJourneysByIds - User Milestone Metric to be inserted
   * @return      mapMilestoneMetricByTypeByJourneyId - map of Milestone Metrics by Type by Journey Id
   * @revision     20.09.2020 - APRivera - Created
   *******************************************************************************/
  public static Map<Id, Map<String, List<String>>> getMilestoneMetricsByJourneyId(Map<Id, Journey__c> mapJourneysByIds) {
    Map<Id, Map<String, List<String>>> mapMilestoneMetricByTypeByJourneyId = new Map<Id, Map<String, List<String>>>();
    for (Journey__c journey : mapJourneysByIds.values()) {
      if (!journey.Milestone_Metrics__r.isEmpty()) {
        Map<String, List<String>> mapMilestoneMetricByType = new Map<String, List<String>>();
        for (Milestone_Metric__c mm : journey.Milestone_Metrics__r) {
          if (!mapMilestoneMetricByType.containsKey(mm.Type__c)) {
            mapMilestoneMetricByType.put(mm.Type__c, new List<String>());
            mapMilestoneMetricByType.get(mm.Type__c).add(mm.Tracked_Field__c);
          } else {
            mapMilestoneMetricByType.get(mm.Type__c).add(mm.Tracked_Field__c);
          }
        }

        if (!mapMilestoneMetricByTypeByJourneyId.containsKey(journey.Id)) {
          mapMilestoneMetricByTypeByJourneyId.put(journey.Id,mapMilestoneMetricByType);
        } else {
          mapMilestoneMetricByTypeByJourneyId.get(journey.Id).putAll(mapMilestoneMetricByType);
        }
      }
    }
    return mapMilestoneMetricByTypeByJourneyId;
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         20.09.2020
   * @description  creates User Milestone Metric
   * @param        lstUserMilestoneMetrics - User Milestone Metric to be inserted
   * @param        lstUserMilestones - List of User Milestones
   * @param        mapJourneyIdsByUserJourneyIds - Map of Journey ids by User Journey ids
   * @param        mapMilestoneMetricByTypeByJourneyId - Map of Milestone Metric by Type by Journey Id
   * @revision     20.09.2020 - APRivera - Created
   *******************************************************************************/
  public static void createUserMilestoneMetric(List<Participant_Milestone_Metric__c> lstUserMilestoneMetrics,List<Participant_Milestone__c> lstUserMilestones,
                                        Map<Id, Id> mapJourneyIdsByUserJourneyIds, Map<Id, Map<String, List<String>>> mapMilestoneMetricByTypeByJourneyId) {
    for (Participant_Milestone__c userMilestone : lstUserMilestones) {
      Id journeyId = mapJourneyIdsByUserJourneyIds.get(userMilestone.Journey__c);
      if (mapMilestoneMetricByTypeByJourneyId.containsKey(journeyId)) {
        Map<String, List<String>> mapMilestoneMetricByType = mapMilestoneMetricByTypeByJourneyId.get(journeyId);
        if (mapMilestoneMetricByType.containsKey(userMilestone.Type__c)) {
          for (String strField : mapMilestoneMetricByType.get(userMilestone.Type__c)) {
            Participant_Milestone_Metric__c umm = new Participant_Milestone_Metric__c();
            umm.Metric_Used__c = strField;
            umm.Milestone__c = userMilestone.Id;
            lstUserMilestoneMetrics.add(umm);
          }
        }
      }
    }
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         10.09.2020
   * @description  Retrieves User Journey Template (from Journey Object)
   * @param        userJourney - User Journey being inserted
   * @param        journey - Journey template
   * @param        strJourneyCommunityURL - User Journey Community URL
   * @return       mapJourneysByIds - Map<Id,Journey__c>
   * @revision     10.09.2020 - APRivera - Created
   *                05.02.2020 - ADFrancisco - Added contact Id
   *******************************************************************************/
  public static Journey_Participant__c updateUserJourney(Journey_Participant__c userJourney,Journey__c journey,String strJourneyCommunityURL) {
    Journey_Participant__c uj = new Journey_Participant__c();
    uj.Id = userJourney.Id;
    uj.Description__c = userJourney.Description__c != null ? userJourney.Description__c : journey.Description__c;
    uj.Contact__c = userJourney.Contact__c;
    if (userJourney.Contact__c != null) {
      uj.Journey_URL__c = strJourneyCommunityURL + '/s/journey?journeyId=' + userJourney.Id;
    }
    return uj;
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         10.09.2020
   * @description  Creates Journey's User Milestones
   * @param        lstMilestones - List of Milestones from the Journey template
   * @param        userJourney - User Journey
   * @param        lstUserMilestonesToInsert - List of User Milestones to be inserted
   * @revision     10.09.2020 - APRivera - Created
   *******************************************************************************/
  public static void createUserMilestones(List<Milestone__c> lstMilestones, Journey_Participant__c userJourney, List<Participant_Milestone__c> lstUserMilestonesToInsert) {
    for (Milestone__c milestone : lstMilestones) {
      Participant_Milestone__c userMilestone = new Participant_Milestone__c();
      if (milestone.RecordTypeId ==Schema.SObjectType.Milestone__c.getRecordTypeInfosByName().get('Checkpoint').getRecordTypeId()) {
        //if recordtype = Checkpoint
        userMilestone.Type__c = 'Checkpoint';
        userMilestone.Checkpoint__c = true;
      } else {
        userMilestone.Type__c = milestone.Type__c;
        userMilestone.Checkpoint_Name__c = milestone.Parent__c;
      }
      userMilestone.Journey__c = userJourney.Id;
      userMilestone.Description__c = milestone.Description__c;
      userMilestone.Sort_Order__c = milestone.Sort_Order__c;
      userMilestone.Milestone_URL__c = milestone.Milestone_URL__c;
      userMilestone.System_Generated__c = true;
      userMilestone.Contact__c = userJourney.Contact__c;
      userMilestone.Milestone__c = milestone.Id;
      userMilestone.Start_Date__c = milestone.Start_Date__c;
      userMilestone.End_Date__c = milestone.End_Date__c;
      userMilestone.Parent_Milestone__c = milestone.Parent_Milestone__c;
      userMilestone.Display_In_Dashboard__c = milestone.Display_In_Dashboard__c;
      lstUserMilestonesToInsert.add(userMilestone);
    }
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         19.03.2021
   * @description  Creates Participant Milestone Metrics
   * @param        setJourneyIds - Set Journey Ids
   * @param        lstMetrics - List of Milestone Metrics inserted in the system
   * @param        setMetricType - set of milestone metric types
   * @param        evt - trigger event
   * @revision     19.03.2021 - APRivera - Created
   *******************************************************************************/
  public static void processMilestoneMetric(Set<Id> setJourneyIds, List<Milestone_Metric__c> lstMetrics,
                                            Set<String> setMetricType, String evt) {
    List<Participant_Milestone__c> lstParticipantMilestones = new List<Participant_Milestone__c>();
    lstParticipantMilestones = getParticipantMilestones(
      setJourneyIds,
      setMetricType
    );
    List<Participant_Milestone_Metric__c> lstParticipantMilestoneMetricsToInsert = new List<Participant_Milestone_Metric__c>();
    List<Participant_Milestone_Metric__c> lstParticipantMilestoneMetricsToDelete = new List<Participant_Milestone_Metric__c>();

    for (Milestone_Metric__c milestoneMetric : lstMetrics) {
      if (!lstParticipantMilestones.isEmpty()) {
        for (Participant_Milestone__c pm : lstParticipantMilestones) {
          if (milestoneMetric.Type__c == pm.Type__c) {
            if (evt == 'INSERT') {
              // When Milestone metric is created, insert new Participant_Milestone_Metric__c
              Participant_Milestone_Metric__c umm = new Participant_Milestone_Metric__c();
              umm.Metric_Used__c = milestoneMetric.Tracked_Field__c;
              umm.Milestone__c = pm.Id;
              lstParticipantMilestoneMetricsToInsert.add(umm);
            } else if (evt == 'DELETE') {
              // When Milestone metric is deleted, delete Participant_Milestone_Metric__c
              if (!pm.Participant_Milestone_Metrics__r.isEmpty()) {
                for (
                  Participant_Milestone_Metric__c pmm : pm.Participant_Milestone_Metrics__r
                ) {
                  if (pmm.Metric_Used__c == milestoneMetric.Tracked_Field__c) {
                    lstParticipantMilestoneMetricsToDelete.add(pmm);
                  }
                }
              }
            }
          }
        }
      }
    }

    try {
      if (!lstParticipantMilestoneMetricsToInsert.isEmpty()) {
        Database.insert(lstParticipantMilestoneMetricsToInsert);
      }
    } catch (Exception ex) {
      System.debug(LoggingLevel.DEBUG,'!@# ERROR IN INSERT: ' + ex.getMessage());
    }

    try {
      if (!lstParticipantMilestoneMetricsToDelete.isEmpty()) {
        Database.delete(lstParticipantMilestoneMetricsToDelete);
      }
    } catch (Exception ex) {
      System.debug(LoggingLevel.DEBUG,'!@# ERROR IN DELETE: ' + ex.getMessage());
    }
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         10.09.2020TheProviderJourney
   * @description  Retrieves User Journey
   * @param        setUserJourneyId - Set of User Journey Ids
   * @return       mapUserJourneysByIds - Map<Id, User_Journey__c>
   * @revision     10.09.2020 - APRivera - Created
   *******************************************************************************/
  public static Map<Id, Journey_Participant__c> getUserJourneys(Set<Id> setUserJourneyId) {
    Map<Id, Journey_Participant__c> mapUserJourneysByIds = new Map<Id, Journey_Participant__c>();
    for (Journey_Participant__c usrJourney : new ElevatedContext().getContactUsDetails2(setUserJourneyId)) {
      mapUserJourneysByIds.put(usrJourney.Id, usrJourney);
    }
    return mapUserJourneysByIds;
  }
  /*******************************************************************************
   * @author       Allen Francisco
   * @date         08.02.2021
   * @description  Retrieves all milestone from journey
   * @param        journeyId - Set of User Journey Ids
   * @return       Journey__c
   * @revision     08.02.2021 - ADFrancisco - Created
   *******************************************************************************/
  public static Journey__c getMilestoneFromJourney(Set<Id> journeyId) {
    //CCN-3526 XEN REYES Oct 11 2023
    return new ElevatedContext().getMilestoneFromJourney(journeyId);
  }

  /*******************************************************************************
 * @author       Arivera
 * @date         29.12.2021
 * @description  Retrieves all milestone from journey
 * @param        setJourneyIds - Set of User Journey Ids
 * @return       List of milestones
 * @revision     29.12.2021 - Arivera - Created
 *******************************************************************************/
  public static Map<Id, List<Milestone__c>> getJourneyMilestones(Set<Id> setJourneyIds){
    Map<Id, List<Milestone__c>> mapMilestonesByJourneyId = new Map<Id, List<Milestone__c>>();
    for (Milestone__c milestone : new ElevatedContext().getMilestones(setJourneyIds)) {
      //mapUserJourneysByIds.put(milestone.Journey__c, milestone);
      if(mapMilestonesByJourneyId.containsKey(milestone.Journey__c)){
        mapMilestonesByJourneyId.get(milestone.Journey__c).add(milestone);
      }else{
        mapMilestonesByJourneyId.put(milestone.Journey__c,new List<Milestone__c>());
        mapMilestonesByJourneyId.get(milestone.Journey__c).add(milestone);
      }
    }
    return mapMilestonesByJourneyId;
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         11.09.2020
   * @description  Retrieves User Journey
   * @param        setMilestoneIds - Set of User Milestone Ids
   * @return       mapMilestoneByIds - Map<Id, User_Milestone__c>
   * @revision     11.09.2020 - APRivera - Created   
   * @revision     11.11.2021 - APRivera - Added Is_Active__c on the where clause to exclude inactive milestones
   * @revision     12.24.2021 - DBrinas - Added Display_In_Dashboard__c and Parent_Milestone__c
   *******************************************************************************/
  public static Map<Id, Participant_Milestone__c> getUserMilestones(Set<Id> setMilestoneIds){

    Map<Id, Participant_Milestone__c> mapMilestoneByIds = new Map<Id, Participant_Milestone__c>();

    //CCN-3526 XEN REYES Oct 11 2023
    for(Participant_Milestone__c ma : new ElevatedContext().getUserMilestones(setMilestoneIds)) {
      mapMilestoneByIds.put(ma.Id, ma);
    }
    return mapMilestoneByIds;
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         19.03.2021
   * @description  Retrieves list of Journey Participant Milestones
   * @param        setJourneyIds - Set of User Journey Ids
   * @param        setMetricType - Set of milestone metric types
   * @return       lstParticipantMilestones -  Map<Id, Id>
   * @revision     19.03.2021 - APRivera - Created
   *******************************************************************************/
  public static List<Participant_Milestone__c> getParticipantMilestones(Set<Id> setJourneyIds, Set<String> setMetricType) {
    List<Participant_Milestone__c> lstParticipantMilestones = new List<Participant_Milestone__c>();
    lstParticipantMilestones = [
      SELECT
        Id,
        Type__c,
        Milestone__c,
        (SELECT Id, Metric_Used__c FROM Participant_Milestone_Metrics__r)
      FROM Participant_Milestone__c
      WHERE
        Journey__r.Journey__c IN :setJourneyIds
        AND Type__c IN :setMetricType
        AND Is_Active__c = TRUE
    ];
    return lstParticipantMilestones;
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         19.03.2021
   * @description  Retrieves Journey participants and related Participant milestones
   * @param        setJourneyIds - Journey set of Ids
   * @return       lstParticipantMilestonesByIds - List<Journey_Participant__c>
   * @revision     19.03.2021 - APRivera - Created
   * @revision     11.11.2021 - APRivera - Added Is_Active__c on the where clause to exclude inactive milestones
   * @revision     24.12.2021 - DBrinas - Added the Journey__c field in the query
   * @revision     15.12.2023 - APRivera - Added new fields in the soql
   *******************************************************************************/
  public static List<Journey_Participant__c> getJourneyParticipantsWithMilestones(Set<Id> setJourneyIds) {
    List<Journey_Participant__c> lstParticipantMilestonesByIds = new List<Journey_Participant__c>();
    lstParticipantMilestonesByIds = [SELECT Id, (SELECT Id, Name, Description__c, Sort_Order__c, Milestone_URL__c, Type__c, Completion__c, Is_Active__c, Milestone__r.Catch_Up_Completion_Button__c,
                                      Milestone__r.Session_Catch_Up_Start_Date__c, Milestone__r.Session_Catch_Up_End_Date__c, Parent_Milestone__c,
                                      Contact__c, Milestone__c, Milestone__r.Name, Milestone__r.Survey_Completion_Button__c, Milestone__r.Survey_Completion_Button_Text__c,Milestone__r.Related_RecordId__c,Milestone__r.Quick_Check_Begin_Button_Text__c,
                                      Milestone_Progress__c, Progress__c,System_Generated__c, Total_Completed_Metrics__c, Total_Number_Of_Metrics__c, Checkpoint__c,
                                      Checkpoint_Progress__c, Start_Date__c, End_Date__c,Journey__c, Milestone__r.Attestation_Completion_Button__c, Milestone__r.Attestation_Completion_Button_Text__c
                                      FROM Participant_Milestones__r WHERE Is_Active__c = TRUE)
                                      FROM Journey_Participant__c
                                      WHERE Journey__c IN :setJourneyIds];
    return lstParticipantMilestonesByIds;
  }

  /*******************************************************************************
 * @author       Angelo Rivera
 * @date         17.01.2022
 * @description  Retrieves Journey participants and related Participant milestones
 * @param        setJourneyIds - Journey set of Ids
 * @param        setMilestoneIds - Set of Milestone Ids
 * @return       mapParticipantMilestonesByParticipantIds - Map<Id, List<Participant_Milestone__c>>
 * @revision     17.01.2022 - APRivera - Created
 * @revision     15.12.2023 - APRivera - Added new fields in the soql
 *******************************************************************************/
  public static Map<Id, List<Participant_Milestone__c>> getParticipantsWithMilestones(Set<Id> setJourneyIds, Set<Id> setMilestoneIds) {
    Map<Id, List<Participant_Milestone__c>> mapParticipantMilestonesByParticipantIds = new Map<Id, List<Participant_Milestone__c>>();

    for(Participant_Milestone__c pm : [SELECT Id, Name, Description__c, Sort_Order__c, Milestone_URL__c, Type__c, Completion__c, Is_Active__c, Milestone__r.Catch_Up_Completion_Button__c,
                                        Milestone__r.Session_Catch_Up_Start_Date__c, Milestone__r.Session_Catch_Up_End_Date__c, Parent_Milestone__c,
                                        Contact__c, Milestone__c, Milestone__r.Name, Milestone__r.Survey_Completion_Button__c, Milestone__r.Survey_Completion_Button_Text__c, Milestone__r.Related_RecordId__c,Milestone__r.Quick_Check_Begin_Button_Text__c,
                                        Milestone_Progress__c, Progress__c, System_Generated__c, Total_Completed_Metrics__c, Total_Number_Of_Metrics__c, Checkpoint__c,
                                        Checkpoint_Progress__c, Start_Date__c, End_Date__c, Journey__c, Journey__r.Journey__c, Milestone__r.Attestation_Completion_Button__c, Milestone__r.Attestation_Completion_Button_Text__c
                                        FROM Participant_Milestone__c
                                        WHERE Is_Active__c = TRUE
                                        AND Journey__r.Journey__c IN: setJourneyIds
                                        AND Milestone__c IN: setMilestoneIds]){

      if(!mapParticipantMilestonesByParticipantIds.containsKey(pm.Journey__c)){
        mapParticipantMilestonesByParticipantIds.put(pm.Journey__c, new List<Participant_Milestone__c>());
        mapParticipantMilestonesByParticipantIds.get(pm.Journey__c).add(pm);
      }else{
        mapParticipantMilestonesByParticipantIds.get(pm.Journey__c).add(pm);
      }
    }
    return mapParticipantMilestonesByParticipantIds;
  }


  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         24.12.2021
   * @description  Retrieves Journey participants and related Participant milestones
   * @param        journeyId - Journey set of Ids
   * @return       lstParticipantMilestones - List<Participant_Milestone__c>
   * @revision     24.12.2021 - APRivera - Created
   * @revision     24.12.2021 - DBrinas - Added Parent_Milestone__c and Display_In_Dashboard__c
   *******************************************************************************/
  public static List<Participant_Milestone__c> getJourneyParticipantMilestones(Id journeyId) {
    List<Participant_Milestone__c> lstParticipantMilestones = new List<Participant_Milestone__c>();
    List<Participant_Milestone__c> lstParticipantMilestones_final = new List<Participant_Milestone__c>(); // Added by DinoBrinas [CCN973] Deec242021

    //CCN-3526 XEN REYES Oct 11 2023
    lstParticipantMilestones = new ElevatedContext().getJourneyParticipantMilestones(journeyId);

    for(Participant_Milestone__c pm: lstParticipantMilestones){
      if(pm.Display_In_Dashboard__c <> null && pm.Display_In_Dashboard__c){
        lstParticipantMilestones_final.add(pm);
      } else if(pm.Parent_Milestone__c == null){
        lstParticipantMilestones_final.add(pm);
      } else{
        System.debug(' @@@@@ Do not display in the journey dashboard');
      }
    }
    return lstParticipantMilestones_final;
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         10.09.2020
   * @description  Retrieved the ma of Journey Ids by User Journey Ids
   * @param        setUserJourneyId - Set of User Journey Ids
   * @return       mapJourneyIdsByUserJourneyIds -  Map<Id, Id>
   * @revision     10.09.2020 - APRivera - Created
   *******************************************************************************/
  public static Map<Id, Id> getJourneyIds(Set<Id> setUserJourneyId) {
    Map<Id, Id> mapJourneyIdsByUserJourneyIds = new Map<Id, Id>();
    for (Journey_Participant__c usrJourney : [
      SELECT Id, Name, Journey__c
      FROM Journey_Participant__c
      WHERE Id IN :setUserJourneyId
    ]) {
      mapJourneyIdsByUserJourneyIds.put(usrJourney.Id, usrJourney.Journey__c);
    }
    return mapJourneyIdsByUserJourneyIds;
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         10.09.2020
   * @description  Retrieves Journey
   * @param        setJourneyIds - Journey set of Ids
   * @return       mapJourneysByIds - Map<Id,Journey__c>
   * @revision     10.09.2020 - APRivera - Created
   *******************************************************************************/
  public static Map<Id, Journey__c> getJourney(Set<Id> setJourneyIds) {
    Map<Id, Journey__c> mapJourneysByIds = new Map<Id, Journey__c>();
    for (Journey__c journey : [SELECT Id, Name, Description__c, Status__c, Event__c,
                                (SELECT Id, Name, Type__c, Tracked_Field__c FROM Milestone_Metrics__r)
                              FROM Journey__c WHERE Id IN :setJourneyIds]) {
      mapJourneysByIds.put(journey.Id, journey);
    }
    return mapJourneysByIds;
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         15.10.2020
   * @description  Retrieves Journey and Journey participants
   * @param        setJourneyIds - Journey set of Ids
   * @return       mapJourneysByIds - Map<Id,Journey__c>
   * @revision     15.10.2020 - APRivera - Created
   *******************************************************************************/
  public static Map<Id, List<Journey_Participant__c>> getJourneyParticipantsByJourneyIds(Set<Id> setJourneyIds  ) {
    Map<Id, List<Journey_Participant__c>> mapJourneyParticipantsByJourneyIds = new Map<Id, List<Journey_Participant__c>>();

    for(Journey_Participant__c jp : [SELECT Id, Contact__c, Journey__c
                                    FROM Journey_Participant__c WHERE Journey__c IN: setJourneyIds]){
      if(mapJourneyParticipantsByJourneyIds.containsKey(jp.Journey__c)){
        mapJourneyParticipantsByJourneyIds.get(jp.Journey__c).add(jp);
      }else{
        mapJourneyParticipantsByJourneyIds.put(jp.Journey__c, new List<Journey_Participant__c>());
        mapJourneyParticipantsByJourneyIds.get(jp.Journey__c).add(jp);
      }
    }
    return mapJourneyParticipantsByJourneyIds;
  }

    /*******************************************************************************
   * @author       Kyzer Buhay
   * @date         05.31.2021
   * @description  Queries Participant Milestone Metric which will then be updated
   * @param        participantMilestoneId 
   * @return       ParticipantMilestoneMetric record
   *******************************************************************************/
    public static Participant_Milestone_Metric__c getParticipantMilestoneMetric(String participantMilestoneId){
      //CCN-3526 XEN REYES Oct 11 2023
      return new ElevatedContext().getParticipantMilestoneMetric(participantMilestoneId);
    }
    
    /*******************************************************************************
    * @author       Kyzer Buhay
    * @date         05.02.2021
    * @description  Queries Journey Participant and related object details without sharing
    * @revision     11.11.2021 - APRivera - CreatedAdded Is_Active__c on the where clause to exclude inactive milestones
    * @revision     15.12.2023 - APRivera - Added new fields in the soql
    *******************************************************************************/
    without sharing class ElevatedContext{ 
        public List<Journey_Participant__c> getContactUsDetails(Set<Id> setUserJourneyId){
            return [SELECT Id, Name, Contact__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email,
                    Contact__r.Phone, Contact__r.Profile_Picture_URL__c, Is_Active__c, Description__c, Journey__r.Name,
                    Journey__c, Journey__r.CreatedById, Journey_Progress__c, Journey__r.Contact_Us_Tag_Line__c,
                    Journey__r.Contact_Us_Message__c, Journey__r.Subtitle__c, Journey__r.Journey_Image_URL__c, Journey__r.Campaign_Logo_URL__c,
                    Journey__r.Journey_Preview_URL__c,
            (SELECT Id, Name, Description__c, Sort_Order__c, Milestone_URL__c, Type__c, Completion__c, Is_Active__c, Milestone__r.Catch_Up_Completion_Button__c,
                    Milestone__r.Session_Catch_Up_Start_Date__c, Milestone__r.Session_Catch_Up_End_Date__c,
                    Contact__c, Milestone__c, Milestone__r.Name, Milestone__r.Survey_Completion_Button__c, Milestone__r.Survey_Completion_Button_Text__c, Milestone__r.Related_RecordId__c,Milestone__r.Quick_Check_Begin_Button_Text__c,Milestone__r.Add_Quick_Check_Begin_Button__c,
                    Milestone_Progress__c, Progress__c, System_Generated__c, Total_Completed_Metrics__c, Total_Number_Of_Metrics__c, Checkpoint__c,
                    Checkpoint_Progress__c, Start_Date__c, End_Date__c, Parent_Milestone__c, Display_In_Dashboard__c,
                    Milestone__r.Attestation_Completion_Button__c, Milestone__r.Attestation_Completion_Button_Text__c
            FROM Participant_Milestones__r WHERE Is_Active__c = true
            ORDER BY Sort_Order__c ASC)
            FROM Journey_Participant__c
            WHERE Id IN :setUserJourneyId];
        }

      public List<Journey_Participant__c> getContactUsDetails2(Set<Id> setUserJourneyId){
            return [SELECT Id, Name, Contact__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email,
                                              Contact__r.Phone, Contact__r.Profile_Picture_URL__c, Is_Active__c, Description__c, Journey__r.Name,
                                              Journey__c, Journey__r.CreatedById, Journey_Progress__c, Journey__r.Contact_Us_Tag_Line__c,
                                              Journey__r.Contact_Us_Message__c, Journey__r.Subtitle__c, Journey__r.Journey_Image_URL__c, Journey__r.Campaign_Logo_URL__c,
                                              Journey__r.Journey_Preview_URL__c, Journey_Target_Progress__c
                                              FROM Journey_Participant__c
                                              WHERE Id IN :setUserJourneyId];
        }

      public List<Milestone__c> getMilestones(Set<Id> setUserJourneyId){
        return [SELECT Id, RecordTypeId, RecordType.Name, Name, Sort_Order__c, Description__c,Journey__c, Milestone_URL__c, Is_Active__c,
                Type__c, Checkpoint__c, Parent__c, Start_Date__c, End_Date__c, Parent_Milestone__c, Display_In_Dashboard__c
                FROM Milestone__c WHERE Is_Active__c = TRUE AND Journey__c IN :setUserJourneyId ORDER BY Sort_Order__c ASC];
      }

      //CCN-3526 XEN REYES Oct 11 2023
      public Journey__c getMilestoneFromJourney(Set<Id> journeyId) {
       return [SELECT Id,Name, Description__c, CreatedById, (SELECT Id, Name, Checkpoint__c, Type__c, Milestone_URL__c, Sort_Order__c FROM Milestones__r ORDER BY Sort_Order__c ASC) FROM Journey__c WHERE Id = :journeyId LIMIT 1];
      }

      public Participant_Milestone_Metric__c getParticipantMilestoneMetric(String participantMilestoneId){
        return [SELECT Id, Completion_Date__c,  Milestone__c, Milestone__r.Contact__c, Milestone__r.Checkpoint_Name__c
                FROM Participant_Milestone_Metric__c WHERE Milestone__r.Id =: participantMilestoneId LIMIT 1];
      }

      public List<Participant_Milestone__c> getUserMilestones(Set<Id> setMilestoneIds){
        return [SELECT Id,
                  Name,
                  Description__c,
                  Sort_Order__c,
                  Milestone_URL__c,
                  Type__c,
                  Completion__c,
                  Is_Active__c,
                  Contact__c,
                  Milestone__c,
                  Milestone__r.Name,
                  Milestone__r.Description__c,
                  Milestone_Progress__c,
                  System_Generated__c,
                  Total_Completed_Metrics__c,
                  Total_Number_Of_Metrics__c,
                  Checkpoint__c,
                  Start_Date__c,
                  End_Date__c,
                  Parent_Milestone__c, Display_In_Dashboard__c, // Added by DinoBrinas [CCN973] Dec242021
                  (
                    SELECT Id, Name, Milestone__c, Metric_Used__c, Completion_Date__c
                    FROM Participant_Milestone_Metrics__r
                  ),
                  (
                    SELECT Id, Subject, Description, Sort_Order__c
                    FROM Tasks
                    WHERE Type = 'Related Information'
                    ORDER BY Sort_Order__c ASC
                  )
                FROM Participant_Milestone__c
                WHERE Id IN :setMilestoneIds AND Is_Active__c = TRUE AND ((Parent_Milestone__c != null AND Display_In_Dashboard__c = TRUE) OR Display_In_Dashboard__c = FALSE) // Added by DinoBrinas [CCN973] Dec242021
                ORDER BY Sort_Order__c ASC];
      }
//      * @revision     15.12.2023 - APRivera - Added new fields in the soql
      public List<Participant_Milestone__c> getJourneyParticipantMilestones(Id journeyId){
        return [SELECT Id, Journey__c, Name, Description__c, Sort_Order__c, Milestone_URL__c, Type__c, Completion__c, Is_Active__c, Milestone__r.Catch_Up_Completion_Button__c,
                  Milestone__r.Session_Catch_Up_Start_Date__c, Milestone__r.Session_Catch_Up_End_Date__c,
                  Contact__c, Milestone__c, Milestone__r.Name, Milestone__r.Survey_Completion_Button__c, Milestone__r.Survey_Completion_Button_Text__c, Milestone__r.Related_RecordId__c,Milestone__r.Quick_Check_Begin_Button_Text__c,Milestone__r.Add_Quick_Check_Begin_Button__c,
                  Milestone_Progress__c, Progress__c, System_Generated__c, Total_Completed_Metrics__c, Total_Number_Of_Metrics__c, Checkpoint__c,
                  Checkpoint_Progress__c, Start_Date__c, End_Date__c, Milestone__r.Attestation_Completion_Button__c, Milestone__r.Attestation_Completion_Button_Text__c,
                  Display_In_Dashboard__c, Parent_Milestone__c // Added by DinoBrinas [CCN973] Deec242021
                  FROM Participant_Milestone__c WHERE Is_Active__c = TRUE
                  AND Journey__c =: journeyId ORDER BY Sort_Order__c ASC];
      }

    }
    /*******************************************************************************
     * @author       DinoBinas
     * @date         14-01-2022
     * @description  Delete of Journey Participant
     * @param        journeyId
     * @return       return string empty
     *******************************************************************************/
    @AuraEnabled
    public static String deleteJourneyPartWhereTotalMilZero(Id journeyId){
      String returnEmpty = '';
      List<Journey_Participant__c> lstJP = new List<Journey_Participant__c>();
      for(Journey_Participant__c jp: [SELECT Id, Total_Milestones__c FROM Journey_Participant__c WHERE Journey__c =:String.valueof(journeyId)]) {
        if(jp.Total_Milestones__c == 0){ 
          lstJP.add(jp);
        }
      }
      if(lstJP <> null && lstJP.size() > 0){
        delete lstJP;
      }
      return returnEmpty;
    }



    /*******************************************************************************
    * @author       APR
    * @date         08-07-2022
    * @description  Retrieve Total number per Participant Milestone Status of Journey Participant
    * @param        participantId - Journey Participant Id
    * @return       JourneyParticipantWrapper journeyParticipantWrapper
    *******************************************************************************/
    @AuraEnabled
    public static JourneyParticipantWrapper getJourneyParticipantInfo(Id participantId){
      JourneyParticipantWrapper journeyParticipantWrapper = new JourneyParticipantWrapper();

      if(participantId != null){

        Journey_Participant__c jp = new Journey_Participant__c();
        journeyParticipantWrapper.mapTotalNumberOfMilestoneStatus = new Map<String, Integer>();
        journeyParticipantWrapper.participantProgress = '';
        journeyParticipantWrapper.journeyProgress = '';
        journeyParticipantWrapper.startedParticipantMilestones = '';
        journeyParticipantWrapper.completedParticipantMilestones = '';
        journeyParticipantWrapper.totalParticipantMilestones = '';

        jp = [SELECT Id, Journey_Progress__c, Journey_Target_Progress__c, Started_Participant_Milestones__c, Total_Completed_Milestones__c, Total_Milestones__c,
                (SELECT Id, Milestone_Status__c, Journey__c, Is_Active__c, Checkpoint__c, Child_Milestone__c, Parent_Milestone__c
                  FROM Participant_Milestones__r
                    WHERE Is_Active__c = TRUE
                    AND Checkpoint__c = FALSE
                    AND Child_Milestone__c = FALSE
                    AND Parent_Milestone__c = NULL
                    AND Milestone_Status__c != NULL)
              FROM Journey_Participant__c WHERE Id =: participantId];

        journeyParticipantWrapper.participantProgress = String.valueOf(jp.Journey_Progress__c);
        journeyParticipantWrapper.journeyProgress = String.valueOf(jp.Journey_Target_Progress__c);
        journeyParticipantWrapper.startedParticipantMilestones = String.valueOf(jp.Started_Participant_Milestones__c);
        journeyParticipantWrapper.completedParticipantMilestones = String.valueOf(jp.Total_Completed_Milestones__c);
        journeyParticipantWrapper.totalParticipantMilestones = String.valueOf(jp.Total_Milestones__c);

        if(!jp.Participant_Milestones__r.isEmpty()){
          for(Participant_Milestone__c pm : jp.Participant_Milestones__r){
            if(!journeyParticipantWrapper.mapTotalNumberOfMilestoneStatus.containsKey(pm.Milestone_Status__c)){
              journeyParticipantWrapper.mapTotalNumberOfMilestoneStatus.put(pm.Milestone_Status__c, 1);
            }
            else{
              Integer ctr =  0;
              ctr = journeyParticipantWrapper.mapTotalNumberOfMilestoneStatus.get(pm.Milestone_Status__c) + 1;
              journeyParticipantWrapper.mapTotalNumberOfMilestoneStatus.put(pm.Milestone_Status__c,ctr);
            }
          }
        }

      }
      return journeyParticipantWrapper;
    }

  /*******************************************************************************
   * @author       APR
   * @date         08-07-2022
   * @description  Wrapper class for Journey Participant
   *******************************************************************************/
    public class JourneyParticipantWrapper {
        @AuraEnabled
        public  Map<String,Integer> mapTotalNumberOfMilestoneStatus {get; set;}
        @AuraEnabled
        public String participantProgress {get; set;}
        @AuraEnabled
        public String journeyProgress {get; set;}
        @AuraEnabled
        public String startedParticipantMilestones {get; set;}
        @AuraEnabled
        public String completedParticipantMilestones {get; set;}
        @AuraEnabled
        public String totalParticipantMilestones {get; set;}
    }

}