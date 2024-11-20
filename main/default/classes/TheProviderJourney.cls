/**
 * @description Controller class for 'JourneyPage' Aura Component
 * @revision
 *           11.09.2020 - APRivera - Updated Class
 **/
public with sharing class TheProviderJourney {
  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         11.09.2020
   * @description  Wrapper Class for User Journey, Milestone, Metrics and Actions
   * @revision     11.09.2020 - APRivera - Created
   *******************************************************************************/
  public class UserJourneyWrapperClass {
      @AuraEnabled
      public Journey_Participant__c userJourney {
          get;
          set;
      }
      @AuraEnabled
      public List < Participant_Milestone__c > lstUserMilestones {
          get;
          set;
      } 
      @AuraEnabled
      //public Map <String, List<Quick_Check_Answer__c >> lstQuickCheckAnswer {
      public List<Quick_Check_Answer__c > lstQuickCheckAnswer {
          get;
          set;
      }
      @AuraEnabled
      public Map < String, List < Participant_Milestone_Metric__c >> mapMetricsByMilestoneName {
          get;
          set;
      }
      @AuraEnabled
      public Map < String, List < Task >> mapTasksByMilestoneName {
          get;
          set;
      }
      @AuraEnabled
      public List < Milestone__c > journeyMilestoneList;
      @AuraEnabled
      public Journey__c journeyData;
      @AuraEnabled
      public Boolean urlFromJourney;
      @AuraEnabled
      public String CampaignLogoURL;
      @AuraEnabled
      public String JourneyLogoURL;
      //MMALLORCA 03/05/2024 CCN-JOU-3713-DV
      @AuraEnabled
      public Map<Id, List<Quick_Check_Question__c>> quickCheckQuestions;
      @AuraEnabled
      public String contactId;
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         11.09.2020
   * @description  Retrieves User Journey Record with related User Milestone, Actions and Metrics
   * @param        strJourneyId - List of User Milestones to be processed
   * @return       journeyWrapper - instance of UserJourneyWrapperClass
   * @revision     11.09.2020 - APRivera - Created
   * @revision     12.24.2020 - APRivera - CCN-1086 - Fixed milestone data volume issue
   *******************************************************************************/
  @AuraEnabled
  public static UserJourneyWrapperClass getUserJourney(Id strJourneyId) {
      UserJourneyWrapperClass journeyWrapper = new UserJourneyWrapperClass();
      try {

          Set < Id > setJourneyIds = new Set < Id > ();
          Set < Id > setUserJourneyIds = new Set < Id > ();
          String objectNameOfId = strJourneyId.getSObjectType()
              .getDescribe()
              .getName();

          objectNameOfId = objectNameOfId.remove('beta_ccn__').remove('compass_cn__');
          System.debug(LoggingLevel.DEBUG, '!@# objectNameOfId: ' + objectNameOfId);
          setUserJourneyIds.add(strJourneyId);
          //retrieves User Journey Record
          Map < Id, Journey_Participant__c > mapUserJourneysByIds = new Map < Id, Journey_Participant__c > ();
          if (objectNameOfId.contains('Journey_Participant__c')) {
              mapUserJourneysByIds = JourneyParticipantServices.getUserJourneys(setUserJourneyIds);
              System.debug(LoggingLevel.DEBUG, '!@# mapUserJourneysByIds: ' + mapUserJourneysByIds.size());
              journeyWrapper.urlFromJourney = false;

              if (!mapUserJourneysByIds.isEmpty()) {
                  journeyWrapper.userJourney = new Journey_Participant__c();
                  journeyWrapper.lstUserMilestones = new List < Participant_Milestone__c > ();
                  journeyWrapper.userJourney = mapUserJourneysByIds.get(strJourneyId);
                  setJourneyIds.add(journeyWrapper.userJourney.Journey__c);
                  journeyWrapper.CampaignLogoURL = journeyWrapper.userJourney.Journey__r.Campaign_Logo_URL__c;
                  journeyWrapper.JourneyLogoURL = journeyWrapper.userJourney.Journey__r.Journey_Image_URL__c;

                  List < Participant_Milestone__c > lstJourneyParticipantsMilestones = new List < Participant_Milestone__c > ();
                  lstJourneyParticipantsMilestones = JourneyParticipantServices.getJourneyParticipantMilestones(strJourneyId);
                  
                  //MMALLORCA 03/05/2024 CCN-JOU-3713-DV
                  List<Journey_Participant__c> jpList = [Select Id, Journey__c, Contact__c From Journey_Participant__c Where Id=:strJourneyId];
                  Map<Id, Id> journeyContact = new Map<Id, Id>();
                  Set<Id> journeySet = new Set<Id>(); 
                  Set<Id> contactId = new Set<Id>();
                  for(Journey_Participant__c jp: jpList){
                      journeySet.add(jp.Journey__c);
                      journeyContact.put(jp.Id, jp.Contact__c);
                      contactId.add(jp.Contact__c);
                  }
                  
                  List<Milestone__c> milestoneList = [SELECT Id, RecordTypeId, RecordType.Name, Name, Sort_Order__c, Description__c,Journey__c, Milestone_URL__c, Is_Active__c,
                                                      Related_RecordId__c, Type__c, Checkpoint__c, Parent__c, Start_Date__c, End_Date__c, Parent_Milestone__c, Display_In_Dashboard__c
                                                      FROM Milestone__c WHERE Is_Active__c = TRUE AND Journey__c IN:journeySet AND Related_RecordId__c != null
                                                      ORDER BY Sort_Order__c ASC];
                  Set<Id> quickCheckSet = new Set<Id>();
                  Map<Id, Id> milestoneQuickCheckMap = new Map<Id, Id>();
                  Map<Id, Id> quickCheckMilestoneMap = new Map<Id, Id>();
                  for(Milestone__c m : milestoneList){
                      quickCheckSet.add(m.Related_RecordId__c);
                  }
                  
                  journeyWrapper.contactId = journeyContact.get(strJourneyId);
                  List<Quick_Check_Response__c> qcrList = [Select Id, Contact__c, Quick_Check__c 
                                                           From Quick_Check_Response__c 
                                                           Where Quick_Check__c IN: quickCheckSet 
                                                           AND Contact__c IN: contactId];
                  
                  Set<Id> quickCheckIds = new Set<Id>();
                  for(Quick_Check_Response__c qcr: qcrList){
                      quickCheckIds.add(qcr.Quick_Check__c);
                  }
                  List<Quick_Check_Answer__c> qcaList = [Select Id, Answer__c, Answer_Checking__c, Quick_Check_Question_Number__r.Correct_Answer_s__c,
                                                         Contact__c, Question__c, Quick_Check__c, Quick_Check_Question_Number__c,
                                                         Quick_Check_Response_Number__c, Quick_Check_Question_Number__r.Quick_Check__c,
                                                         Quick_Check_Question_Number__r.Quick_Check__r.Id, isLatest__c, QuickCheckId__c, 
                                                         ContactId__c, Quick_Check_Question_Number__r.Completion_Message__c
                                                         From Quick_Check_Answer__c 
                                                         Where Quick_Check_Question_Number__r.Quick_Check__c IN:quickCheckIds
                                                         AND  Quick_Check_Response_Number__r.Contact__r.Id IN: contactId 
                                                         AND isLatest__c = true
                                                         ORDER By Quick_Check_Question_Number__r.Sort_Order__c ASC];
                  
                  Map<String, List<Quick_Check_Answer__c>> qcaMap = new Map<String, List<Quick_Check_Answer__c>>();
                  List<String> hey = new List<String>();
                  for(Quick_Check_Answer__c qca: qcaList){
                      if(qcaMap.containsKey(qca.Quick_Check_Question_Number__r.Quick_Check__r.Id)){
                          qcaMap.get(qca.Quick_Check_Question_Number__r.Quick_Check__r.Id).add(qca);
                      }
                      else{
                          qcaMap.put(qca.Quick_Check_Question_Number__r.Quick_Check__r.Id, new List<Quick_Check_Answer__c> {qca});
                      }
                  }
                  journeyWrapper.lstQuickCheckAnswer = qcaList;
                  
                  if (!lstJourneyParticipantsMilestones.isEmpty()) {
                      journeyWrapper.lstUserMilestones.addAll(lstJourneyParticipantsMilestones);
                      Set < Id > setMilestoneIds = new Set < Id > ();
                      for (Participant_Milestone__c um: journeyWrapper.lstUserMilestones) {
                          setMilestoneIds.add(um.Id);
                      }
                      System.debug('+++ setMilestoneIds' + setMilestoneIds);

                      if (!setMilestoneIds.isEmpty()) {
                          Map < Id, Participant_Milestone__c > mapMilestoneByIds = JourneyParticipantServices.getUserMilestones(setMilestoneIds);
                          journeyWrapper.mapMetricsByMilestoneName = new Map < String, List < Participant_Milestone_Metric__c >> ();
                          journeyWrapper.mapTasksByMilestoneName = new Map < String, List < Task >> ();
                          for (Participant_Milestone__c um: mapMilestoneByIds.values()) {
                              //retrieves User Milestone Metrics
                              if (!um.Participant_Milestone_Metrics__r.isEmpty()) {
                                  journeyWrapper.mapMetricsByMilestoneName.put(
                                      um.Name,
                                      um.Participant_Milestone_Metrics__r
                                  );
                              }
                              //retrieves User Milestone Actions
                              if (!um.Tasks.isEmpty()) {
                                  journeyWrapper.mapTasksByMilestoneName.put(um.Name, um.Tasks);
                              }
                          }
                      }
                  }
                  
                  //MMALLORCA 03/05/2024 CCN-JOU-3713-DV
                  //Retrieve Quick Check Questions based on Journey Assignments junction object
                  Map<Id, List<Quick_Check_Question__c>> lstJourneyQuickCheckQuestions = new Map<Id, List<Quick_Check_Question__c>>();
                  lstJourneyQuickCheckQuestions = JourneyParticipantServices.getJourneyQuickCheckQuestions(strJourneyId);
                  journeyWrapper.quickCheckQuestions = lstJourneyQuickCheckQuestions;
                  //MMALLORCA 03/05/2024 CCN-JOU-3713-DV
              }
              System.debug('+++ setJourneyIds' + setJourneyIds);
              Journey__c jData = JourneyParticipantServices.getMilestoneFromJourney(setJourneyIds);
              journeyWrapper.journeyMilestoneList = jData.Milestones__r;
              journeyWrapper.journeyData = jData;
          } else if (objectNameOfId.contains('Journey__c')) {
              setJourneyIds.add(strJourneyId);
              Journey__c jData = JourneyParticipantServices.getMilestoneFromJourney(setJourneyIds);
              journeyWrapper.journeyMilestoneList = jData.Milestones__r;
              journeyWrapper.journeyData = jData;
              journeyWrapper.urlFromJourney = true;
          }
          System.debug(LoggingLevel.DEBUG, '!@# Data: ' + journeyWrapper);
      } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
      }
      return journeyWrapper;
  }

  /*******************************************************************************
   * @author       Kyzer Buhay
   * @date         05.02.2021
   * @description  Task Creation for Contact Us form submission
   * @param        userJourney - User's Journey to be tagged as Related to and owned by Contact Us User field. If empty, use Journey Owner
   * @return       newTask - newly task record created
   *******************************************************************************/
  @AuraEnabled
  public static Boolean createTaskContactUs(String contactUserId, String fName, String lName, String email, String phone,
      Id userJourney, String subject, String comment) {
      return new ElevatedContext().createTaskWithoutSharing(contactUserId, fName, lName, email, phone, userJourney, subject, comment);
  }

  /*******************************************************************************
   * @author       Kyzer Buhay
   * @date         05.02.2021
   * @description  used in Survey completion Button in dashboard
   * @param        participant Milestone selected in Journey Dashboard
   *******************************************************************************/
  @AuraEnabled
  public static Boolean processSurveyAssessmentComplete(String participantMilestoneId) {
      Boolean hasError = false;
      try {
          Participant_Milestone_Metric__c pmmRecord;
          List < Participant_Milestone__c > participantMilestoneList = new List < Participant_Milestone__c > ();

          if (FlsUtils.isAccessible('Participant_Milestone_Metric__c', new List < String > {
                  'Completion_Date__c'
              })) {
              pmmRecord = JourneyParticipantServices.getParticipantMilestoneMetric(participantMilestoneId);
              pmmRecord.Completion_Date__c = System.now();
              hasError = new ElevatedContext().updateParticipantMilestoneMetric(pmmRecord);
          }

          if (FlsUtils.isAccessible('Participant_Milestone__c', new List < String > {
                  'Contact__c',
                  'Checkpoint_Name__c',
                  'Milestone_Progress__c',
                  'Checkpoint__c'
              })) {
              participantMilestoneList = new ElevatedContext().getParticipantMilestoneCheckpoint(pmmRecord);

              Integer divider = 0;
              Double totalProgress = 0;
              Participant_Milestone__c targetCheckpointPM;
              for (Participant_Milestone__c participantMilestone: participantMilestoneList) {
                  Decimal milestoneProgress = 0;
                  milestoneProgress = participantMilestone.Milestone_Progress__c != null ? participantMilestone.Milestone_Progress__c : 0;
                  if (participantMilestone.Checkpoint__c) {
                      targetCheckpointPM = participantMilestone;
                  } else {
                      divider += 1;
                      totalProgress = totalProgress + milestoneProgress;
                  }
              }

              if (targetCheckpointPM != null) {
                  targetCheckpointPM.Checkpoint_Progress__c = totalProgress / divider;
                  hasError = new ElevatedContext().updateParticipantMilestone(targetCheckpointPM);
              }
          }
      } catch (Exception e) {
          System.debug(e);
          hasError = true;
      }

      return hasError;
  }

  /*******************************************************************************
   * @author       Rianno Rizarri
   * @date         10.17.2021
   * @description  used in Event catch up Button in dashboard
   * @param        participant Milestone selected in Journey Dashboard
   *******************************************************************************/
  @AuraEnabled
  public static Boolean processEventCatchUp(String participantMilestoneId) {
      Boolean hasError = false;
      // try{
      List < Participant_Milestone_Metric__c > participantMilestoneMetrics = new List < Participant_Milestone_Metric__c > ();
      // participantMilestoneMetrics = [
      //     SELECT Id, Milestone__r.Contact__c
      //     FROM Participant_Milestone_Metric__c
      //     WHERE Milestone__c =: participantMilestoneId
      // ];
      Participant_Milestone__c participantMilestone = new Participant_Milestone__c();
      participantMilestone = [SELECT Contact__c, (SELECT Metric_used__c, Completion_Date__c FROM Participant_Milestone_Metrics__r WHERE Metric_used__c IN('Attendance Date', 'Invitation Date', 'Registration Date'))
          FROM Participant_Milestone__c WHERE ID =: participantMilestoneId
      ];
      system.debug(participantMilestoneId);
      system.debug('participantMilestone');
      system.debug(participantMilestone);
      system.debug(participantMilestone != null);
      Boolean hasSession = new ElevatedContext().updateParticipantSession(participantMilestoneId, participantMilestone.Contact__c);
      if (participantMilestoneMetrics != null) {
          for (Participant_Milestone_Metric__c participantMilestoneMetricRec: participantMilestone.Participant_Milestone_Metrics__r) {
              // Updated by RiannoRizarri [CCN843] March252022
              String metricUsed = '';
              if (hasSession) {
                  if (participantMilestoneMetricRec.Metric_used__c == 'Attendance Date') {
                      participantMilestoneMetrics.add(new Participant_Milestone_Metric__c(Id = participantMilestoneMetricRec.Id,
                          Completion_Date__c = System.now(), metric_used__c = 'Catch-Up Date'));
                  } else {
                      if (participantMilestoneMetricRec.Completion_Date__c == null) {
                          participantMilestoneMetrics.add(new Participant_Milestone_Metric__c(Id = participantMilestoneMetricRec.Id,
                              Completion_Date__c = System.now()));
                      }
                  }
              } else {
                  if (participantMilestoneMetricRec.Metric_used__c == 'Attendance Date') {
                      participantMilestoneMetrics.add(new Participant_Milestone_Metric__c(Id = participantMilestoneMetricRec.Id,
                          Completion_Date__c = System.now(), metric_used__c = 'Catch-Up Date'));
                  } else {
                      participantMilestoneMetrics.add(new Participant_Milestone_Metric__c(Id = participantMilestoneMetricRec.Id,
                          Completion_Date__c = null));
                  }
              }

              // Updated by RiannoRizarri [CCN843] March252022
          }

          hasError = new ElevatedContext().updateParticipantMilestoneMetricList(participantMilestoneMetrics);

      }
      // }catch(Exception e){
      //     hasError = true;
      // }

      return hasError;
  }


  Public without sharing class ElevatedContext {
      /*******************************************************************************
       * @author       Kyzer Buhay
       * @date         05.02.2021
       * @description  without sharing actions which access can't be provided to Guest User
       *******************************************************************************/
      public Boolean createTaskWithoutSharing(String contactUserId, String fName, String lName, String email,
          String phone, Id userJourney, String subject, String comment) {
          Boolean hasError = false;
          try {
              Task newTask = new Task();
              Journey__c journeyRec = new Journey__c();
              Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Community_Journey_Contact_Us').getRecordTypeId();
              newTask.RecordTypeId = recordTypeId;

              if (FlsUtils.isAccessible('Journey__c', new List < String > {
                      'Contact_Us_User__c'
                  })) {
                  journeyRec = [SELECT Id, OwnerId, Contact_Us_User__r.Id FROM Journey__c WHERE Id =: userJourney LIMIT 1];
              }
              newTask.OwnerId = String.isEmpty(journeyRec.Contact_Us_User__r.Id) ? journeyRec.OwnerId : journeyRec.Contact_Us_User__c;
              newTask.WhoId = contactUserId;

              newTask.Subject = subject;
              newTask.WhatId = userJourney;
              newTask.Description = comment;
              newTask.Type = 'Email';
              newTask.Task_Origin__c = 'Journey Participant - Contact Us Page';
              newTask.ActivityDate = System.today();
              newTask.Phone_Number__c = phone; //CCN-JOU-1224-DV Xen Reyes 10 Apr 2022

              insert newTask;

              //CCN-JOU-1224-DV Xen Reyes 28 Apr 2022
              List < Contact > conList = [SELECT Id, Phone FROM Contact WHERE Id =: contactUserId LIMIT 1];
              if (!conList.isEmpty()) {
                  if (conList[0].Phone == null && phone != null) {
                      String invalidNumbers = '[^0-9]';
                      conList[0].Phone = phone.replaceAll(invalidNumbers, '');
                      update conList[0];
                  }
              }

          } catch (Exception e) {
              hasError = true;
              System.debug(LoggingLevel.DEBUG, '!@# ERROR IN INSERT: ' + e.getMessage());
          }

          return hasError;
      }

      /*******************************************************************************
       * @author       Kyzer Buhay
       * @date         05.02.2021
       * @description  without sharing dml update for Participant Milestone Metric Records;
       *******************************************************************************/
      public Boolean updateParticipantMilestoneMetric(Participant_Milestone_Metric__c pmmRecord) {
          Boolean hasError = false;
          try {
              if (pmmRecord != null) {
                  update pmmRecord;
              }
          } catch (Exception e) {
              hasError = true;
          }

          return hasError;
      }

      /*******************************************************************************
       * @author       Rianno Rizarri
       * @date         10.17.2021
       * @description  without sharing dml update for Participant Milestone Metric Records;
       *******************************************************************************/
      public Boolean updateParticipantMilestoneMetricList(List < Participant_Milestone_Metric__c > pmmRecord) {
          Boolean hasError = false;
          try {
              if (pmmRecord != null) {
                  update pmmRecord;
              }
          } catch (Exception e) {
              hasError = true;
          }

          return hasError;
      }


      /*******************************************************************************
       * @author       Rianno Rizarri
       * @date         10.17.2021
       * @description  without sharing dml update for Participant Milestone Metric Records;
       *******************************************************************************/
      public Boolean updateParticipantSession(Id participantMilestoneId, Id contactId) {
          Boolean hasSession = false;
          system.debug(participantMilestoneId);
          system.debug(contactId);
          Set < Id > milestoneRelatedRecordSet = new Set < Id > ();
          // Updated by RiannoRizarri [CCN-1609] May 3 2022
          Milestone__c eventMilestone = new Milestone__c();
          eventMilestone = [SELECT Related_RecordId__c
              FROM Milestone__c
              WHERE ID IN(SELECT Milestone__c FROM Participant_Milestone__c WHERE ID =: participantMilestoneId)
          ];
          if (eventMilestone <> null) {
              List < Milestone__c > childMilestones = new List < Milestone__c > ();
              childMilestones = [SELECT Related_RecordId__c
                  FROM Milestone__c
                  WHERE Parent_Milestone__c =: eventMilestone.Id
              ];

              // Updated by RiannoRizarri [CCN-1609] May 5 2022
              if (childMilestones != null && childMilestones.size() > 0) {
                  for (Milestone__c childMilestone: childMilestones) {
                      if (childMilestone.Related_RecordId__c != null) {
                          milestoneRelatedRecordSet.add(childMilestone.Related_RecordId__c);
                      }
                  }
              }
              String objectType = '';
              if (eventMilestone.Related_RecordId__c <> null) {
                  milestoneRelatedRecordSet.add(eventMilestone.Related_RecordId__c);
                  objectType = checkObject(eventMilestone.Related_RecordId__c);
              }
              // Updated by RiannoRizarri [CCN-1609] May 5 2022
              if (objectType == 'Session__c' && milestoneRelatedRecordSet != null && milestoneRelatedRecordSet.size() > 0) {
                  // Updated by RiannoRizarri [CCN843] March252022
                  List < Session_Participant__c > sessionParticipant = new List < Session_Participant__c > ();
                  sessionParticipant = [SELECT Contact__c FROM Session_Participant__c
                      WHERE Session__r.Id IN: milestoneRelatedRecordSet AND(Contact__c =: contactId OR Participant__r.Member_Contact__c =: contactId)
                  ];

                  // Updated by RiannoRizarri [CCN-1609] May 5 2022
                  if (sessionParticipant != null && sessionParticipant.size() > 0) {
                      Session_Participant__c updateSeshPart = new Session_Participant__c();
                      updateSeshPart.Status__c = 'Catchup';
                      updateSeshPart.Catchup_Date__c = System.Now();
                      updateSeshPart.Id = sessionParticipant[0].Id;
                      Update updateSeshPart;
                      hasSession = true;
                  }
                  // Updated by RiannoRizarri [CCN843] March252022
              }
          }
          // Updated by RiannoRizarri [CCN-1609] May 3 2022
          return hasSession;
      }

      /*******************************************************************************
       * @author       Kyzer Buhay
       * @date         05.02.2021
       * @description  without sharing actions which access can't be provided to Guest User
       *******************************************************************************/
      public Boolean updateParticipantMilestone(Participant_Milestone__c pmRecord) {
          Boolean hasError = false;
          try {
              if (pmRecord != null) {
                  //pmmRecord.Completion_Date__c = System.now();
                  update pmRecord;
              }
          } catch (Exception e) {
              hasError = true;
          }

          return hasError;
      }

      public List < Journey_Participant__c > getJourneyViaJourneyAndContact(String journeyId, String contactEmail) {
          return [SELECT Id, Contact__c, Journey_URL__c FROM Journey_Participant__c WHERE Journey__c =: journeyId AND Contact__r.Email =: contactEmail];
      }

      public List < Participant_Milestone__c > getParticipantMilestoneCheckpoint(Participant_Milestone_Metric__c pmmRecord) {
          return [SELECT Id, Contact__c, Checkpoint_Name__c, Milestone_Progress__c, Checkpoint__c
              FROM Participant_Milestone__c
              WHERE Contact__r.Id =: pmmRecord.Milestone__r.Contact__c AND(Checkpoint_Name__r.Id =: pmmRecord.Milestone__r.Checkpoint_Name__c OR Milestone__r.Id =: pmmRecord.Milestone__r.Checkpoint_Name__c)
          ];
      }
  }

  /*******************************************************************************
   * @author       Jayson Sarion
   * @date         05.05.2021
   * @description  Validate email to match Journey Participants
   * @param        inputEmail - user email
   * @param       journeyId - Journey Paricipant that match the Email and Journey
   * @return       journeyId - Journey Paricipant that match the Email and Journey
   *******************************************************************************/
  @AuraEnabled
  public static String validateParticipant(String inputEmail, String journeyId) {
      List < Journey_Participant__c > journeyParticipantList = new List < Journey_Participant__c > ();
      if (FlsUtils.isAccessible('Journey_Participant__c', new List < String > {
              'Journey_URL__c'
          })) {
          journeyParticipantList = new ElevatedContext().getJourneyViaJourneyAndContact(journeyId, inputEmail);
      }
      if (!journeyParticipantList.isEmpty()) {
          return journeyParticipantList[0].Journey_URL__c;
      }

      return 'false';
  }

  /*******************************************************************************
   * @author       Jayson Sarion
   * @date         05.05.2021
   * @description  Check Object instance of ID
   * @param        objId - record Id
   * @return       id object
   *******************************************************************************/
  @AuraEnabled
  public static String checkObject(Id objId) {
      return String.valueOf(objId.getSobjectType()).remove('beta_ccn__').remove('compass_cn__');
  }
    
    /*******************************************************************************
   * @author       Mel Mallorca
   * @date         03.15.2024
   * @description  Save Quick Check Response
    * @param       List of quick check response
   *******************************************************************************/
    @AuraEnabled
    public static void saveAnswers(String finalRes) {
        List<Parameters> pList = (List<Parameters>)JSON.deserialize(finalRes, List<Parameters>.class);
        
        Quick_Check_Response__c qcr = new Quick_Check_Response__c();
        if(pList.size() > 0){
            qcr.Contact__c = pList[0].ContactId;
            qcr.Quick_Check__c = pList[0].QuickCheckId;
            qcr.Participant_Milestone__c = pList[0].ParticipantMilestoneId;
            try{
                insert qcr;
                saveQuickCheckAnswer(finalRes, qcr.Id);
            }
            catch(DmlException e){
                throw new AuraHandledException(e.getMessage());
            }
        }
    }
    
    
    public class Parameters {
        @AuraEnabled
        public String Answer {get; set;}
        @AuraEnabled
        public String QuickCheckId {get; set;}
        @AuraEnabled
        public String QuestionId {get; set;}
        @AuraEnabled
        public String Question {get; set;}
        @AuraEnabled
        public String CorrectAnswers {get; set;}
        @AuraEnabled
        public String ContactId {get; set;}
        @AuraEnabled
        public String ParticipantMilestoneId {get; set;}
        @AuraEnabled
        public String AnswerChecking {get; set;}
        @AuraEnabled
        public String counter {get; set;}
    }
    
    /*******************************************************************************
   * @author       Mel Mallorca
   * @date         03.16.2024
   * @description  Save Quick Check Answers
    * @param       List of quick check answers
   *******************************************************************************/
    @Future
    @AuraEnabled
    public static void saveQuickCheckAnswer(String finalRes, String qcrId){
        List<Parameters> pList = (List<Parameters>)JSON.deserialize(finalRes, List<Parameters>.class);
        List<Quick_Check_Answer__c> qcaList = new List<Quick_Check_Answer__c>();
        for(Parameters p: pList){
            Quick_Check_Answer__c qca = new Quick_Check_Answer__c();
            qca.Question__c = p.Question;
            qca.Answer__c = p.Answer;
            qca.Answer_Checking__c = p.AnswerChecking;
            qca.Quick_Check_Question_Number__c = p.QuestionId;
            qca.Quick_Check_Response_Number__c = qcrId;
            qca.isLatest__c = true;
            qcaList.add(qca);
        }
        // DML commit
        try{
            insert qcaList;
        } catch(DmlException e){
            throw new AuraHandledException(e.getMessage());
        } 
    }    
}