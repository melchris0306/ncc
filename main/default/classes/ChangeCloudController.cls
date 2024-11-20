public with sharing class ChangeCloudController {
    private static WithoutSharingClass withoutShare = new WithoutSharingClass(); 
    private static final String ATTENDED = 'Attended';
    
    @AuraEnabled
    public static CCEEventWrapper getEventDetails(String eventId) { 
        //eventId = '7RvETWUOkMc';
        Event__c campaignRecord;
        CCEEventWrapper eventRecord = new CCEEventWrapper();
        
        try {
            if(FlsUtils.isAccessible('Event__c', new List<String>{'Name','Subtitle__c','Event_Id__c','Hero_Image_URL__c','Campaign_Logo_URL__c',
                'Description__c','Contact_Us_Tag_Line__c','Contact_Us_Message__c', 'OwnerId', 'Start_Date_Time__c','Contact_Us_User__c',
                'Time_Zone__c','Status__c','End_Date_Time__c'}) 
               && FlsUtils.isAccessible('Account', new List<String>{'BillingStreet','BillingCity',
                   'BillingPostalCode','BillingState','BillingCountry','Name'})){
                       
                       campaignRecord = withoutShare.getEvent(eventId);
                   }
            
            eventRecord = setEventWrapperValues(campaignRecord, null);
            
        } catch(QueryException ex) {
            throw new AuraHandledException('Invalid event Id');
        }
        
        return eventRecord;
    }
    
    @AuraEnabled
    public static CCEEventWrapper getEventDetailsHeader(String eventId, String pm) { 
        
        CCEEventWrapper eventRecord = new CCEEventWrapper();
        
        try {
            //eventId = '7RvETWUOkMc';
            Event__c campaignRecord = new Event__c();
            if(FlsUtils.isAccessible('Event__c', new List<String>{'Name','Subtitle__c','Event_Id__c','Hero_Image_URL__c','Campaign_Logo_URL__c',
                'Description__c','Contact_Us_Tag_Line__c','Contact_Us_Message__c', 'OwnerId', 'Start_Date_Time__c','Contact_Us_User__c',
                'Time_Zone__c','Status__c','End_Date_Time__c'}) 
               && FlsUtils.isAccessible('Account', new List<String>{'BillingStreet','BillingCity',
                   'BillingPostalCode','BillingState','BillingCountry','Name'})){
                       
                       campaignRecord = withoutShare.getEvent(eventId);
                   }
            
            List<Participant__c> contactRec;
            
            if(FlsUtils.isAccessible('Contact', new List<String>{'FirstName'})){
                contactRec = withoutShare.getParticipant(pm);
            }
            
            eventRecord = setEventWrapperValues(campaignRecord, (!contactRec.isEmpty()) ? contactRec[0] : null);
            
        } catch (QueryException ex) {
            throw new AuraHandledException('Invalid event Id');
        }
        
        return eventRecord;
    }
    
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  ??           ??                   Initial version.
    * @version   2.0  10-06-2022   VonPernicia          [CCN-1757] added condition to get list of users timezone
    ******************************************************************************/
    @AuraEnabled
    public static CCEEventWrapper getEventSession(String eventId, String participantNumber, Boolean pstrue) {
        //eventId = 'pwB1UJeYAyh';
        
        List<Session_Participant__c> sessions = new List<Session_Participant__c>();
        Map<Id,Session_Participant__c> sessionMap = new Map<Id,Session_Participant__c>();
        
        if(FlsUtils.isAccessible('Session_Participant__c', new List<String>{'Session__c','Status__c'}) 
           && FlsUtils.isAccessible('Participant__c', new List<String>{'Name'}) 
           && String.isNotBlank(participantNumber)){
               
               sessions = withoutShare.getSessionParticipant(participantNumber);
           }
        
        for(Session_Participant__c sp : sessions){
            sessionMap.put(sp.Session__c,sp);
        }
        
        Event__c campaignRecord = new Event__c();
        
        try {
            if(FlsUtils.isAccessible('Event__c', new List<String>{'OwnerId','Contact_Us_User__c'})){
                campaignRecord = withoutShare.getEvent(eventId);
            }
        } catch (QueryException ex) {
            throw new AuraHandledException('Invalid event Id');
        }
        
        Id userIdToBaseTimezone = campaignRecord.Contact_Us_User__c != null 
            ? campaignRecord.Contact_Us_User__c
            : campaignRecord.OwnerId;
        String timezone = withoutShare.getUserTimezone(userIdToBaseTimezone);
        //String strTZone = [SELECT Id, TimeZoneSidKey FROM Organization LIMIT 1].TimeZoneSidKey;
        String strTZone = timezone;
        
        List<Session__c> campaignList = new List<Session__c>();
        if(FlsUtils.isAccessible('Session__c', new List<String>{'Name','Subtitle__c','Start_Date_Time__c','End_Date_Time__c','Description__c','Time_Zone__c'})){
            campaignList = withoutShare.getSessions(eventId); 
        }
        
        CCEEventWrapper returnResult = new CCEEventWrapper();
        returnResult.orgTimeZone = [SELECT Id, TimeZoneSidKey FROM Organization].TimeZoneSidKey; /*Added for CCN-1070 Jan.15.2022*/
        returnResult.SessionsWithGeneralMaterial = campaignRecord.Sessions_with_General_Materials__c;
        returnResult.SessionList = new List<CCEEventWrapper.SessionDetail>();
        
        Map<String,CCEEventWrapper.SessionDetail> sessionDateHeaderMap = new Map<String,CCEEventWrapper.SessionDetail>();
        Map<String,List<CCEEventWrapper.SessionDetailrec>> sessionDateMap = new Map<String,List<CCEEventWrapper.SessionDetailrec>>();
        
        Set<Id> sessionIds = (new Map<Id,SObject>(campaignList)).keySet();
        
        Map<Id,List<CCEEventWrapper.MaterialWrapper>> materialMap = MaterialsControllerHelper.getSessionMaterialsHelper(sessionIds);
        returnResult.eventmaterialstr = MaterialsControllerHelper.getMaterialsHelper(eventId);
        
        // Start [CCN-1757]: Get List of Users Time Zone
        Set<Id> campLastModByIDList = new Set<Id>();
        for(Session__c CampaignRec : campaignList){
            campLastModByIDList.add(CampaignRec.lastModifiedById);
        }
        
        Map<Id, User> campLastModByTimeZoneMap = new Map<Id, User>();
        for(User u: withoutShare.getUserTimezone(campLastModByIDList)) {
            
            campLastModByTimeZoneMap.put(u.Id, u);
        }
        // End [CCN-1757]: Get List of Users Time Zone

        for(Session__c CampaignRec : campaignList){
            String startDate =  CampaignRec.Start_Date_Time__c.format('MMM d', strTZone);
            
            if(sessionMap.containsKey(CampaignRec.Id) || !pstrue){
                
                CCEEventWrapper.SessionDetailrec sessionRec = new CCEEventWrapper.SessionDetailrec();
                String sessTimezone = campLastModByTimeZoneMap.get(CampaignRec.lastModifiedById).TimeZoneSidKey;// Start [CCN-1757]: Get List of Users Time Zone
                sessionRec.title  = CampaignRec.Name;
                sessionRec.sessionId = CampaignRec.Id;
                sessionRec.subtitle  = CampaignRec.Description__c;
                sessionRec.StartTime  = CampaignRec.Start_Date_Time__c.format('h:mm a', sessTimezone);
                sessionRec.EndTime  = CampaignRec.End_Date_Time__c.format('h:mm a', sessTimezone);
                sessionRec.unformattedStartDate = CampaignRec.Start_Date_Time__c;
                sessionRec.unformattedEndDate = CampaignRec.End_Date_Time__c;
                sessionRec.isCatchup = CampaignRec.Catch_up__c;
                sessionRec.unformattedCatchupStartDate = CampaignRec.Catchup_Start_Date__c;
                sessionRec.unformattedCatchupEndDate = CampaignRec.Catchup_End_Date__c;
                sessionRec.TimeZone  = CampaignRec.Time_Zone__c;
                sessionRec.materialList = materialMap.get(CampaignRec.Id);
                
                if (sessionMap.containsKey(CampaignRec.Id)){
                    sessionRec.participantSessionId = sessionMap.get(CampaignRec.Id).Id;
                    sessionRec.isAttended = sessionMap.get(CampaignRec.Id).Status__c == ATTENDED;
                }
                
                if(sessionDateMap.get(startDate) == null){
                    List<CCEEventWrapper.SessionDetailrec> SessionDetailList = new List<CCEEventWrapper.SessionDetailrec>();
                    
                    SessionDetailList.add(sessionRec);
                    sessionDateMap.put(startDate, SessionDetailList);
                    
                } else {
                    List<CCEEventWrapper.SessionDetailrec> SessionDetailList = sessionDateMap.get(startDate);
                    
                    SessionDetailList.add(sessionRec);
                    sessionDateMap.put(startDate, SessionDetailList);
                }
                
                CCEEventWrapper.SessionDetail SessionHeaderRec = new CCEEventWrapper.SessionDetail();
                SessionHeaderRec.isHeader = true;
                //SessionHeaderRec.SessionDate = String.valueOf(CampaignRec.Start_Date_Time__c.day());
                //SessionHeaderRec.SessionMonth = (String.valueOf(CampaignRec.Start_Date_Time__c.format('MMM'))).toUpperCase();
                //SessionHeaderRec.SessionMonthName = String.valueOf(CampaignRec.Start_Date_Time__c.format('MMMM'));
                //SessionHeaderRec.SessionYear = String.valueOf(CampaignRec.Start_Date_Time__c.year());
                SessionHeaderRec.SessionDate = String.valueOf(CampaignRec.Start_Date_Time__c.format('dd',sessTimezone));
                SessionHeaderRec.SessionMonth = (String.valueOf(CampaignRec.Start_Date_Time__c.format('MMM',sessTimezone))).toUpperCase();
                SessionHeaderRec.SessionMonthName = String.valueOf(CampaignRec.Start_Date_Time__c.format('MMMM',sessTimezone));
                SessionHeaderRec.SessionYear = String.valueOf(CampaignRec.Start_Date_Time__c.format('yyyy',sessTimezone));
                SessionHeaderRec.sessionPageTitle = CampaignRec.Event__r.Sessions_Page_Title__c;
                sessionDateHeaderMap.put(startDate,SessionHeaderRec);
            }
            
        }
        
        
        
        for(String startDate : sessionDateHeaderMap.keySet()){ 
            
            CCEEventWrapper.SessionDetail sessionresult = new CCEEventWrapper.SessionDetail();
            sessionresult = sessionDateHeaderMap.get(startDate);
            sessionresult.SessionDetailList = sessionDateMap.get(startDate);
            returnResult.SessionList.add(sessionresult);
            
        }
        
        return returnResult;
    }
    
    @AuraEnabled
    public static String getEventMaterials(String eventId) {
        return MaterialsControllerHelper.getMaterialsHelper(eventId);
    }
    
    
    @AuraEnabled
    public static List<CCESpeakerWrapper> getSpeakerDetails(String eventId) {
        
        //eventId = '7RvETWUOkMc';
        List<CCESpeakerWrapper> speakerList = new List<CCESpeakerWrapper>();
        Event__c campaignRecord = new Event__c();
        
        try {
            if(FlsUtils.isAccessible('Event__c', new List<String>{'Name'})){
                campaignRecord = withoutShare.getEventName(eventId);
            }
        }catch (QueryException ex) {
            throw new AuraHandledException('Invalid event Id');
        }
        
        List<Event_Role__c> eventRoleList = new List<Event_Role__c>();
        if(FlsUtils.isAccessible('Contact', new List<String>{'FirstName','LastName','Title','Profile_Description__c','Profile_Picture_URL__c'})){
            eventRoleList = withoutShare.getEventRole(campaignRecord.Id); 
        }
        
        for(Event_Role__c er : eventRoleList){
            CCESpeakerWrapper speaker = new CCESpeakerWrapper();
            speaker.FirstName = er.Contact__r.FirstName;
            speaker.lastName = er.Contact__r.lastName;
            speaker.Title = er.Contact__r.Title;
            speaker.Description = er.Contact__r.Profile_Description__c;
            speaker.ProfilePicUrl = er.Contact__r.Profile_Picture_URL__c;
            speaker.isHideProfilePic = String.isEmpty(speaker.ProfilePicUrl) ? true : false;
            speakerList.add(speaker);
        }
        
        return speakerList;
    }
    
    @AuraEnabled
    // Create task for each request sent from the custom contact support form
    public static void createTask(String eventId, String firstname, String lastname, String email, String phone, String subject, String comments){
        
        if (String.isBlank(eventId) || String.isBlank(firstname) || String.isBlank(lastname) || String.isBlank(email) 
            || String.isBlank(subject) || String.isBlank(comments)) {
                
                return;   
            }
        
        CustomContactSupportFormHelper.createTaskHelper(eventId, firstname, lastname, email, phone, subject, comments);
    }
    
    @AuraEnabled
    public static List<compass_session_wrapper> getParticipantSession(String participantNumber) {
        List<Session_Participant__c> sessions = new List<Session_Participant__c>();
        
        //participantNumber = 'EM-000070';
        if(FlsUtils.isAccessible('Session_Participant__c', new List<String>{'Status__c','Session__c'})
           && FlsUtils.isAccessible('Session__c', new List<String>{'Start_Date_Time__c','End_Date_Time__c'})){
               
               sessions = withoutShare.getSessionParticipant(participantNumber);
           }
        
        List<compass_session_wrapper> participantsessions = new List<compass_session_wrapper>();
        
        for(Session_Participant__c session : sessions){
            compass_session_wrapper participantsession = new compass_session_wrapper();
            
            participantsession.selected =  false;
            participantsession.status =  session.Status__c;
            participantsession.participantSessionId =  session.Id;
            participantsession.title =  session.Session__r.Name;
            
            participantsessions.add(participantsession);
        }
        
        return participantsessions;
    }
    
    @AuraEnabled
    public static Boolean catchUpSession(String ParticipantSessionId, String EventId) {
        Session_Participant__c sp = new Session_Participant__c();
        sp.Id = (Id)ParticipantSessionId;
        sp.Catchup_Date__c = DateTime.now();
        sp.Status__c = 'Catchup';
        
        try{
            //used iscreateable instead since we can't grant edit access for Session Participant in object-level
            //if(true){
            //    throw new AuraHandledException(ParticipantSessionId + ' ' + EventId);
            //}
            withoutShare.updateSessionParticipant(sp);
            withoutShare.updateMilestoneMetrics(ParticipantSessionId, EventId);
            if(FlsUtils.isCreateable(sp, new List<String>{'Status__c'})){
                
            } else {
                //throw new AuraHandledException('not creatable'); 
                //return false;  
            }
            
            return true;   
        }
        
        catch(DmlException e){
            system.debug(e);
            throw new AuraHandledException(ParticipantSessionId + ' ' + EventId + ' ' + e.getMessage()); 
        }
    }
    
    //CCN-1070 02/08/2022
    public class ChangeCloudControllerException extends Exception{}
    
    @AuraEnabled
    public static Boolean updateAttendance(String ParticipantSessionId) {
        
        Session_Participant__c sp = new Session_Participant__c();
        sp.Id = ParticipantSessionId;
        sp.Attendance_Date__c = DateTime.now();
        sp.Status__c = ATTENDED;
        
        try{
            //used iscreateable instead since we can't grant edit access for Session Participant in object-level
            //CCN-1070 02/08/2022
            List<String> apiNames = new List<String>{'Status__c'}; 
            if(FlsUtils.isAccessible('Session_Participant__c', apiNames)){
                withoutShare.updateSessionParticipant(sp);
            } else {
                //Updated for CCN-1070 02/08/2022
                String apiName;
                for(String api : apiNames){
                    if(!FlsUtils.isAccessible('Session_Participant__c', new List<String>{api})){
                        apiName = api;
                        break;
                    }
                }
                throw new ChangeCloudControllerException('User '+UserInfo.getUserId()+' has insufficient field access to '+apiName+' on Session_Participant__c'); 
            }
            
            return true;   
        }
        
        catch(DmlException e){
            //Addedd for CCN-1070 02/08/2022
            throw new ChangeCloudControllerException(e.getMessage());
        }
    }
    
    /** Utility Classes */
    /*******************************************************************************************
    * @name: setEventWrapperValues
    * @author: ??
    * @created: ??
    * @description:
    *
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   ??           		??                    ??
    *             2.0   12-07-2022          Edison Crisostomo     [CCN-EVE-1841-DV] - Updated to include CompanyLogoURL
    *             3.0   08-25-2022          Mel Mallorca          [CCN-EVE-2012-DV] Add field values
    *******************************************************************************************/
    private static CCEEventWrapper setEventWrapperValues(Event__c campaignRecord, Participant__c participantRec){
        CCEEventWrapper eventRecord = new CCEEventWrapper();
        
        Id userIdToBaseTimezone = campaignRecord.Contact_Us_User__c != null 
            ? campaignRecord.Contact_Us_User__c
            : campaignRecord.OwnerId;
        String timezone = withoutShare.getUserTimezone(userIdToBaseTimezone);
        String strTZone = [SELECT Id, TimeZoneSidKey FROM Organization LIMIT 1].TimeZoneSidKey;
        //String strTZone = timezone;
        
        if(participantRec != null){
            eventRecord.firstName = participantRec.Member_Contact__r.FirstName;
        }
        
        eventRecord.EventExternalId = campaignRecord.Event_Id__c;
        eventRecord.title = campaignRecord.Name;
        eventRecord.subtitle = campaignRecord.Subtitle__c;
        eventRecord.HeroUrl = campaignRecord.Hero_Image_URL__c;
        eventRecord.CampaignLogoUrl= campaignRecord.Campaign_Logo_URL__c;
        eventRecord.CompanyLogoURL= campaignRecord.Company_Logo_URL__c;
        eventRecord.Street = campaignRecord.Location__r.BillingStreet;
        eventRecord.City = campaignRecord.Location__r.BillingCity;
        eventRecord.PostalCode = campaignRecord.Location__r.BillingPostalCode;
        eventRecord.State = campaignRecord.Location__r.BillingState;
        eventRecord.Country = campaignRecord.Location__r.BillingCountry;
        eventRecord.LocationName = campaignRecord.Location__r.Name;
        eventRecord.Description = campaignRecord.Description__c; 
        eventRecord.contactTag = campaignRecord.Contact_Us_Tag_Line__c; 
        eventRecord.contactMessage = campaignRecord.Contact_Us_Message__c;
        if(campaignRecord.Start_Date_Time__c != null){
            eventRecord.StartDateTime = campaignRecord.Start_Date_Time__c.format('MMMM d, yyyy h:mm a', strTZone) + ' ' + campaignRecord.Time_Zone__c;
        } 
        if(campaignRecord.End_Date_Time__c != null){
            eventRecord.EndDateTime = campaignRecord.End_Date_Time__c.format('MMMM d, yyyy h:mm a', strTZone) + ' ' + campaignRecord.Time_Zone__c;
        }       
        eventRecord.CampaignStatus = campaignRecord.Status__c;
        eventRecord.LocationName = campaignRecord.Location__r.Name;
        eventRecord.homePageTitle = campaignRecord.Home_Page_Title__c;
        eventRecord.sessionPageTitle = campaignRecord.Sessions_Page_Title__c;
        eventRecord.materialsPageTitle = campaignRecord.Materials_Page_Title__c;
        eventRecord.issueTrackerPageTitle = campaignRecord.Issue_Tracker_Page_Title__c;
        eventRecord.parkingPageTitle = campaignRecord.Parking_Lot_Page_Title__c;
        eventRecord.surveyPageTitle = campaignRecord.Survey_Page_Title__c;
        eventRecord.contactUsPageTitle = campaignRecord.Contact_Us_Page_Title__c;
        eventRecord.learnMorePageTitle = campaignRecord.Learn_More_Page_Title__c;
        eventRecord.eventPages = campaignRecord.Event_Pages__c;
        eventRecord.showLogin = campaignRecord.Personalized_Event_Page_Login_Button__c;
        eventRecord.SessionsWithGeneralMaterial = campaignRecord.Sessions_with_General_Materials__c;
        eventRecord.eventURL = campaignRecord.Event_Page_URL__c;
        eventRecord.showToLinks = campaignRecord.Show_To_Links__c;
        //Start [CCN-EVE-2012-DV] Add field values
        eventRecord.sessionCalendarURL = campaignRecord.Sessions_Calendar_Page_URL__c;
        eventRecord.showSessionCalendarLink = campaignRecord.Add_Session_Calendar_to_Summary_Page__c;
        //End [CCN-EVE-2012-DV] Add field values
        
        return eventRecord;
    }
    
    @AuraEnabled
    public static Participant__c getParticipantDetail(String emailstr,String eventId) { 
        Participant__c participantRec = new Participant__c();
        participantRec =  withoutShare.getParticipant(emailstr,eventId);
        return participantRec;
    }
    
    @AuraEnabled
    public static Participant__c getParticipantDetailByNumber(String participantNumber) { 
        Participant__c participantRec = new Participant__c();
        participantRec =  withoutShare.getParticipantByNumber(participantNumber);
        return participantRec;
    }
    
    //Start [CCN-EVE-2173-DV] Added param for Event Type and Event Name MelMallorca Nov262022
    @AuraEnabled
    public static List<CCEEventWrapper> getEventsList(String campaignId, List<String> eventTypes, List<String> eventNames) {
    //End [CCN-EVE-2173-DV] MelMallorca Nov262022
        List<Event__c> eventList;
        List<CCEEventWrapper> resultList = new List<CCEEventWrapper>();
        try {
            if(FlsUtils.isAccessible('Event__c', new List<String>{'Name','Subtitle__c','Event_Id__c','Hero_Image_URL__c','Campaign_Logo_URL__c',
                'Description__c','Contact_Us_Tag_Line__c','Contact_Us_Message__c', 'OwnerId', 'Start_Date_Time__c','Contact_Us_User__c',
                'Time_Zone__c','Status__c','End_Date_Time__c'}) 
               && FlsUtils.isAccessible('Account', new List<String>{'BillingStreet','BillingCity',
                   'BillingPostalCode','BillingState','BillingCountry','Name'})){
                       //Start [CCN-EVE-2173-DV] Added param for Event Type and Event Name MelMallorca Nov262022
                       eventList = withoutShare.getEvents(campaignId, eventTypes, eventNames);
                       //End [CCN-EVE-2173-DV] MelMallorca Nov262022
                       for(Event__c eventRec : eventList){
                           CCEEventWrapper eventWrapper = new CCEEventWrapper();
                           eventWrapper = setEventWrapperValues(eventRec, null);
                           resultList.add(eventWrapper);
                       }
                   }
        } catch(QueryException ex) {
            throw new AuraHandledException('Invalid event Id');
        }
        return resultList;
    }
    
    //Start [CCN-EVE-2173-DV] Added param for Event Type and Event Name MelMallorca Nov262022
    @AuraEnabled
    public static List<CCEEventWrapper> getSortedEventsList(String campaignId, String sortType, List<String> eventTypes, List<String> eventNames) {  
        //End [CCN-EVE-2173-DV] MelMallorca Nov262022
        List<Event__c> eventList;
        List<CCEEventWrapper> resultList = new List<CCEEventWrapper>();
        try {
            if(FlsUtils.isAccessible('Event__c', new List<String>{'Name','Subtitle__c','Event_Id__c','Hero_Image_URL__c','Campaign_Logo_URL__c',
                'Description__c','Contact_Us_Tag_Line__c','Contact_Us_Message__c', 'OwnerId', 'Start_Date_Time__c','Contact_Us_User__c',
                'Time_Zone__c','Status__c','End_Date_Time__c'}) 
               && FlsUtils.isAccessible('Account', new List<String>{'BillingStreet','BillingCity',
                   'BillingPostalCode','BillingState','BillingCountry','Name'})){
                       //Start [CCN-EVE-2173-DV] Added param for Event Type and Event Name MelMallorca Nov262022
                       eventList = withoutShare.getSortedEvents(campaignId,sortType, eventTypes, eventNames);
                       //End [CCN-EVE-2173-DV] MelMallorca Nov262022
                       for(Event__c eventRec : eventList){
                           CCEEventWrapper eventWrapper = new CCEEventWrapper();
                           eventWrapper = setEventWrapperValues(eventRec, null);
                           resultList.add(eventWrapper);
                       }
                   }
        } catch(QueryException ex) {
            throw new AuraHandledException('Invalid event Id');
        }
        return resultList;
    }
    @AuraEnabled
    public static Session__c getSessionDetails(String sessionId) { 
        Session__c session = new Session__c();
        session = withoutShare.getSessionDetails(sessionId);
        return session;
    }
    @AuraEnabled
    public static List<Session_Role__c> getSessionRoles(String sessionId) { 
        List<Session_Role__c> sessionroles = new List<Session_Role__c>();
        sessionroles = withoutShare.getSessionRoles(sessionId);
        return sessionroles;
    }
    @AuraEnabled
    public static List<Session_Participant__c> getSessionParticipants(String sessionId) { 
        List<Session_Participant__c> sessionParticipant = new List<Session_Participant__c>();
        sessionParticipant = withoutShare.getSessionParticipants(sessionId);
        return sessionParticipant;
    }
    @AuraEnabled
    public static String setSessionParticipantsStatus(String participantId) { 

        Session_Participant__c sp = new Session_Participant__c();
        sp.Id = participantId;
        sp.Status__c = 'Attended';
        try {
            withoutShare.updateSessionParticipant(sp);
        } catch(QueryException ex) {
            return 'Error';
        }
        return  'Success';
    }

        /*******************************************************************************************
    * @name: addSessionParticipants
    * @author: ??
    * @created: ??
    * @description:
    *
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -----------------------------
    * @version    1.0   ??           		??                    ??
    *             2.0   09-10-2022          Jayson Labnao         [CCN-EVE-2160-DV]: Added rank parameter
    *******************************************************************************************/
    @AuraEnabled
    public static String addSessionParticipants(String eventId,String sessionId,String firstName,String lastName,String role,String email,String rank, String rankGroup, String site) { 
        try {        

            String roleDescription = '';
            Contact resultContact;
            Participant__c resultParticipant;

            List<Session_Role__c> Roles = withoutShare.getSessionRoles(sessionId);
            for(Session_Role__c rolerec : Roles){
                if(rolerec.Role_Title__c == role){
                    roleDescription = rolerec.Role_Description__c;
                }
            }

            List<Contact> contactList = withoutShare.getContacts(email);
            if(contactList.size() > 0){
                // Start CCN-EVE-3426-DV 10/7/23: Von Pernicia
                contactList[0].Site__c = site;
                resultContact = withoutShare.updateContact(contactList[0]);
                // End CCN-EVE-3426-DV 10/7/23: Von Pernicia
            } else {
                Contact contact = new Contact();
                contact.FirstName = firstName;
                contact.LastName = lastName;
                contact.Email = email;
                contact.Site__c = site;//Added by Gabriel Delavin CCN-EVE-3426-DV
                resultContact  = withoutShare.createContact(contact);
            }

            Event__c event  = withoutShare.getEventName(eventId);
            List<Participant__c> participantList = withoutShare.getParticipants(email,eventId);
            if(participantList.size() > 0){
                resultParticipant = participantList[0];
            } else {
                Participant__c participant = new Participant__c();
                participant.Event__c = event.Id;
                participant.Member_Contact__c = resultContact.Id;

                /* CCN-EVE-2500-DV XEN REYES 30Jan2023 */
                //participant.Status__c = 'Attended';
                
                resultParticipant  = withoutShare.createParticipant(participant);
            }

            SessionParticipantTriggerHandler.isFromAttendancePage = true; //CCN-1038 XR 27 May 2022
            Session_Participant__c sessionParticipant = new Session_Participant__c();
            sessionParticipant.Contact__c = resultContact.Id;
            sessionParticipant.Session__c = sessionId;
            sessionParticipant.Role__c = role;
            sessionParticipant.Role_Description__c = roleDescription;
            sessionParticipant.Status__c = 'Attended';
            sessionParticipant.Session__c = sessionId;
            sessionParticipant.Event__c = event.Id;
            sessionParticipant.Participant__c = resultParticipant.Id;
            sessionParticipant.Rank__c = rank; // Added by JaysonLabnao [CCN-EVE-2160-DV] October102022
            sessionParticipant.Branch_of_Service__c = rankGroup; //XEN REYES March 5, 2023 CCN-EVE-2631-DV
            withoutShare.createSessionParticipant(sessionParticipant);


        } catch (Exception e) {
            return 'Error' + e.getMessage();
        }
        return  'Success';
    }

    // Added By JaysonLabnao [CCN-EVE-2160-DV] OCT092022
    public class PicklistOption{
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}
    }

    // Added By JaysonLabnao [CCN-EVE-2160-DV] OCT092022
    @AuraEnabled
    public static List<PicklistOption> getRankPicklists(){
        List<PicklistOption> resultOptions = new List<PicklistOption>();

        Schema.DescribeFieldResult fieldResult = Session_Participant__c.Rank__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
            PicklistOption option = new PicklistOption();
            option.label = pickListVal.getLabel();
            option.value = pickListVal.getValue();
			resultOptions.add(option);
		}     
		return resultOptions;
    }

    //XEN REYES March 5, 2023 CCN-EVE-2631-DV
    @AuraEnabled
    public static Map<Object,List<String>> getRankAndRankGroupDependencies() {
        Schema.DescribeFieldResult F = Session_Participant__c.Rank__c.getDescribe();
        Schema.sObjectField T = F.getSObjectField();
        return ChangeCloudController.getDependentPicklistValues(T);
    }

    //XEN REYES March 5, 2023 CCN-EVE-2631-DV
    //Pass dependent field parameter e.g.: Account.YourDependentField__c
    public static Map<Object,List<String>> getDependentPicklistValues(Schema.sObjectField dependentField){
        Map<Object,List<String>> dependentPicklistValues = new Map<Object,List<String>>();
        //Get dependent field result
        Schema.DescribeFieldResult dependentFieldResult = dependentField.getDescribe();
        //Get dependent field controlling field 
        Schema.sObjectField controllerField = dependentFieldResult.getController(); 
        //Check controlling field is not null
        if(controllerField == null){
            return null;
        } 
        //Get controlling field result
        Schema.DescribeFieldResult controllerFieldResult = controllerField.getDescribe();
        //Get controlling field picklist values if controlling field is not a checkbox
        List<Schema.PicklistEntry> controllerValues = (controllerFieldResult.getType() == Schema.DisplayType.Boolean ? null : controllerFieldResult.getPicklistValues());
        
        //It is used to decode the characters of the validFor fields. 
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        
        for (Schema.PicklistEntry entry : dependentFieldResult.getPicklistValues()){
            if (entry.isActive()){
            //The PicklistEntry is serialized and deserialized using the Apex JSON class and it will check to have a 'validFor' field
                List<String> base64chars = String.valueOf(((Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer i = 0; i < controllerValues.size(); i++){
                    Object controllerValue = (controllerValues == null ? (Object) (i == 1) : (Object) (controllerValues[i].isActive() ? controllerValues[i].getLabel() : null));
                    Integer bitIndex = i / 6;
                    Integer bitShift = 5 - Math.mod(i, 6 );
                    if(controllerValue == null || (base64map.indexOf(base64chars[bitIndex]) & (1 << bitShift)) == 0){
                        continue;
                    } 
                    if (!dependentPicklistValues.containsKey(controllerValue)){
                        dependentPicklistValues.put(controllerValue, new List<String>());
                    }
                    dependentPicklistValues.get(controllerValue).add(entry.getLabel());
                }
            }
        }
        return dependentPicklistValues;
    }
    
    /*******************************************************************************************
        * @name: getEventFieldRegistrationMdt
        * @author: Leif Erickson de Gracia
        * @created: Sept 8, 2023
        * @description: CCN-EVE-3304-DV
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -------------------------------
        * @version    1.0   08-09-2023        Leif Erickson de Gracia   Initial Version
        *********************************************************************************************/
    private static Map < String, Registration_Field_Configuration__mdt > getEventFieldRegistrationMdt() {
        Map < String, Registration_Field_Configuration__mdt > regFieldConfig = new Map < String, Registration_Field_Configuration__mdt > ();
        for (Registration_Field_Configuration__mdt config: [SELECT Label, Order__c, Field_API_Name__c, Field_Type__c, Is_Required__c, Picklist_Options__c,
                                                            Object_API_Name__c, DeveloperName, Message_when_Required__c, Actual_Field_Type__c,
                                                            Use_event_field__c, Event_Picklist_Field_API_Name__c, //CCN-907 XEN REYES 11032021
                                                            Has_null_picklist_value__c, //CCN-EVE-1881-DV XEN REYES 18072022
                                                            Use_Picklist_Field_from_related_object__c, Related_Object_Field_API__c, Related_Object_Picklist_Field_API__c //XEN REYES CCN-SUR-3235-DV 14 July 2023
                                                            FROM Registration_Field_Configuration__mdt
                                                            WHERE Is_Active__c = true
                                                            ORDER BY Order__c
                                                            LIMIT 5000
                                                           ]) {
                                                               
                                                               //Updated [CCN3301] title override; Since the future plan is to map the TitleRank to the title field in Contact
                                                               regFieldConfig.put(config.DeveloperName + '-' + config.Object_API_Name__c + '|' + config.Field_API_Name__c, config);
                                                               
                                                           }
        return regFieldConfig;
    }
    
        
    /*******************************************************************************************
        * @name: getFieldConfig
        * @author: Leif Erickson de Gracia
        * @created: Sept 8, 2023
        * @description: CCN-EVE-3304-DV
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -------------------------------
        * @version    1.0   08-09-2023        Leif Erickson de Gracia   Initial Version
        *********************************************************************************************/
    @AuraEnabled
    public static resultWrapper getFieldConfig(String sessionId) {
        
        System.debug('getFieldConfig');
        String campaignId = [SELECT Id, Event_Id__c FROM Session__c WHERE Id = : sessionId].Event_Id__c;
        System.debug(campaignId);
        resultWrapper returnResult = new resultWrapper();
        WithoutSharingClass withoutShare = new WithoutSharingClass();
        
        List < Event__c > campaignRec = new List < Event__c > ();
        
        String strTZone = [SELECT Id, TimeZoneSidKey FROM Organization LIMIT 1].TimeZoneSidKey;
        
        //CCN-907 XEN REYES 11032021 - Adding the fields defined in the Event_Picklist_Field_API_Name__c from Registration Field Custom Metadata
        Map < String, Registration_Field_Configuration__mdt > regConfigMap = getEventFieldRegistrationMdt();
        Set < String > fieldsToAddSet = new Set < String > (); //to avoid duplicates
        String additionalFieldsToQuery = '';
        
        System.debug(regConfigMap);
        
        if (!regConfigMap.values().isEmpty()) {
            for (Registration_Field_Configuration__mdt regVar: regConfigMap.values()) {
                if (regVar.Event_Picklist_Field_API_Name__c != null) fieldsToAddSet.add(regVar.Event_Picklist_Field_API_Name__c);
                
                //XEN REYES CCN-SUR-3235-DV 14 July 2023
                if(regVar.Field_Type__c == 'Picklist' && regVar.Use_Picklist_Field_from_related_object__c && regVar.Related_Object_Field_API__c != null && regVar.Related_Object_Picklist_Field_API__c != null){
                    fieldsToAddSet.add(regVar.Related_Object_Field_API__c + '.' + regVar.Related_Object_Picklist_Field_API__c);
                }
            }
            
            //Construct the string to append to dynamic query
            if (!fieldsToAddSet.isEmpty()) {
                List < String > fieldsToAddList = new List < String > (fieldsToAddSet);
                additionalFieldsToQuery = ',';
                for (Integer i = 0; i <= fieldsToAddList.size() - 1; i++) {
                    if (i != fieldsToAddSet.size() - 1) {
                        additionalFieldsToQuery += fieldsToAddList[i] + ',';
                    } else {
                        additionalFieldsToQuery += fieldsToAddList[i] + ' ';
                    }
                }
            }
        }
        
        // campaignId = 'g3UZle8Tnj1';
        // Added for CRUD/FLS Enforcement
        if (FlsUtils.isAccessible('Event__c', new List < String > {
            'Name',
                'OwnerId',
                'Contact_Us_User__c',
                'Time_Zone__c',
                'Event_Id__c'
                })) {
                    //CCN-907 XEN REYES 11032021 - added parameter for dynamic query
                    campaignRec = withoutShare.getEvents(campaignId, additionalFieldsToQuery);
                    
                }
       
        //CCN-907 XEN REYES 11032021 - Updated, added new parameter
        List < RegistrationFields > regFieldMappingList = CC_EventRegistrationClass.getRegistrationFieldConfiguration(campaignRec.get(0).Registration_Fields_JSON__c, campaignRec.get(0).Id, campaignRec[0], regConfigMap);
        List < String > contactFieldsToQuery = new List < String > ();
        System.debug(regFieldMappingList);
        for (RegistrationFields regFieldRecord: regFieldMappingList) {
            if (String.isNotBlank(regFieldRecord.fieldName) &&
                regFieldRecord.objectName == 'Contact' &&
                !contactFieldsToQuery.contains(regFieldRecord.fieldName)) {
                    contactFieldsToQuery.add(regFieldRecord.fieldName);
                }
        }
        
        System.debug(campaignRec);
        
        if (!campaignRec.isEmpty()) {
            returnResult.registrationFieldList = regFieldMappingList;
            
            return returnResult;
        } else {
            return null;
        }
    }
    
    /*******************************************************************************************
    * @name: resultWrapper
    * @author: Leif Erickson de Gracia
    * @created: Sept 5, 2023
    * @description: CCN-EVE-3304-DV
    *
    * -------------------------------------------------------------------------------------------
    *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
    *       	  ----  ---------------     --------------------  -------------------------------
    * @version    1.0   05-09-2023        Leif Erickson de Gracia   Initial Version
    *********************************************************************************************/
    public class resultWrapper {
        @AuraEnabled public Map < String, String > DefaultFieldValueMapping {
            get;
            set;
        }
        @AuraEnabled public List < RegistrationFields > registrationFieldList {
            get;
            set;
        }
    }
    
    //Needs inner class declared without sharing for guest users to retrieve relevant records
    private without sharing class WithoutSharingClass {
        
        public Contact createContact(Contact contact){
            insert contact;
            return contact;
        }
        // Start CCN-EVE-3426-DV 10/7/23: Von Pernicia
         public Contact updateContact(Contact contact){
            update contact;
            return contact;
        }
        // End CCN-EVE-3426-DV 10/7/23: Von Pernicia
        public List<Contact> getContacts(String email){
            List<Contact> resultContacts = [SELECT FirstName,LastName, Email FROM Contact WHERE Email = :email];
            return resultContacts;
        }
        public Participant__c createParticipant(Participant__c participant){
            insert participant;
            return participant;
        }   
        public Session_Participant__c createSessionParticipant(Session_Participant__c sessionParticipant){
            insert sessionParticipant;
            return sessionParticipant;
        }
        public Participant__c getParticipant(String emailstr,String eventId){
            return [SELECT Member_Contact__r.FirstName, Member_Contact__r.Profile_Picture_URL__c,Member_Contact__r.LastName,Name From Participant__c Where Event__r.Event_Id__c = :eventId AND Member_Contact__r.Email = :emailstr];
        }
        public List<Participant__c> getParticipants(String emailstr,String eventId){
            List<Participant__c> results = [SELECT Member_Contact__r.FirstName, Member_Contact__r.Profile_Picture_URL__c,Member_Contact__r.LastName,Name From Participant__c Where Event__r.Event_Id__c = :eventId AND Member_Contact__r.Email = :emailstr];
            return results;
        }
        public Participant__c getParticipantByNumber(String participantNumber){
            return [SELECT Member_Contact__r.FirstName, Member_Contact__r.Profile_Picture_URL__c,Member_Contact__r.LastName,Member_Contact__c,Name From Participant__c  WHERE Name = :participantNumber];
        }
        
        public void updateSessionParticipant(Session_Participant__c sessionPartipant){
            update sessionPartipant;
        }
        
        public void updateMilestoneMetrics(String participantSessionId,String eventId){
            //eventId = 'Mht0QPQlt6n';
            //participantSessionId = 'a521F000000Tcv2QAC';
            
            Session_Participant__c seshParticipant = [SELECT Event__c, Participant__c, Participant__r.Event__c, 
                                                      Participant__r.Event__r.Journey__c, Participant__r.Member_Contact__c FROM Session_Participant__c 
                                                      WHERE ID =: participantSessionId];
            
            
            Event__c eventRec = [SELECT ID FROM Event__c WHERE Event_Id__c =: eventId];
            
            Milestone__c milestoneRec = [SELECT ID FROM Milestone__c WHERE Related_RecordId__c =: eventRec.Id];
            
            Participant_Milestone__c partMile = [SELECT ID, (SELECT ID, Name FROM Participant_Milestone_Metrics__r) FROM Participant_Milestone__c 
                                                 WHERE Milestone__c =: milestoneRec.Id AND Contact__c =: seshParticipant.Participant__r.Member_Contact__c];
               
            List<Participant_Milestone_Metric__c> metricList = new List<Participant_Milestone_Metric__c>();
            for(Participant_Milestone_Metric__c metric : partMile.Participant_Milestone_Metrics__r){
                metric.Completion_Date__c = System.Now();
                metricList.add(metric);
            }
            Update metricList;
            //if(true){
            //    throw new AuraHandledException(seshParticipant + ' ' + eventRec + ' ' + milestoneRec + ' ' + partMile + ' ketr' + partMile.Participant_Milestone_Metrics__r); 
            //}
        }
        
        public List<Session__c> getSessions(String eventId){
            return [SELECT Id,Name,
                    lastModifiedById,
                    Subtitle__c,  
                    Start_Date_Time__c, 
                    End_Date_Time__c, 
                    Catch_up__c,
                    Catchup_Start_Date__c,
                    Catchup_End_Date__c,
                    Description__c, 
                    Time_Zone__c,
                    Event__r.Sessions_Page_Title__c  
                    FROM Session__c 
                    WHERE Event__r.Event_Id__c = :eventId 
                    AND IsActive__c = true 
                    ORDER BY Start_Date_Time__c];
        }

        public Session__c getSessionDetails(String sessionId){
            return [SELECT Id,Name,
                    lastModifiedById,
                    Subtitle__c,  
                    Start_Date_Time__c, 
                    End_Date_Time__c,
                    Start_Date_Time2__c,
                    End_Date_Time2__c,
                    Catch_up__c,
                    Catchup_Start_Date__c,
                    Catchup_End_Date__c,
                    Description__c, 
                    Time_Zone__c,
                    Event__r.Sessions_Page_Title__c  
                    FROM Session__c 
                    WHERE Id = :sessionId];
        }


        public List<Session_Role__c> getSessionRoles(String sessionId){
            return [SELECT Role_Title__c,Role_Description__c  
                    FROM Session_Role__c WHERE Session__c = :sessionId];
        }

        public List<Session_Participant__c> getSessionParticipant(String participantNumber){
            return [SELECT Id,Name, Status__c,Session__c, Session__r.Name, Session__r.Start_Date_Time__c, Session__r.End_Date_Time__c 
                    FROM Session_Participant__c WHERE Participant__r.Name = :participantNumber];
        }
        
        /******************************************************************************    
        * Changes (version)
        *            No.  Date(dd-mm-yyyy) Author                Description
        *           ----  ---------        --------------------  ----------------------
        * @version   1.0  13-06-2022       Von Pernicia         [CCN-EVE-1755-DV] Added Status__c not in ('Cancelled', 'Declined').
        *            2.0  17-06-2022       Von Pernicia         [CCN-EVE-1773-DV ] - Updated status value from Cancelled to Canceled
        *            2.0  30-07-2022       Jayson Labnao        [CCN-1991] - Added sorting for the list of session participants
        *            2.0  09-10-2022       Jayson Labnao        [CCN-EVE-2160-DV] - Added Rank Field to display in Attendance Page
        ******************************************************************************/
        public List<Session_Participant__c> getSessionParticipants(String sessionId){
            return [SELECT Id, Status__c,Session__c, Rank__c, Role__c, Role_Description__c, Contact__r.LastName , Contact__r.FirstName , Contact__r.Email 
                    FROM Session_Participant__c WHERE Session__c = :sessionId AND Status__c not in ('Canceled', 'Declined') ORDER BY Contact__r.LastName ASC]; //CCN-1991 - JaysonLabnao - July302022
        }

        public List<Participant__c> getParticipant(String participantNumber){
            return [SELECT Id, Member_Contact__r.FirstName, Member_Contact__r.Profile_Picture_URL__c,Member_Contact__r.LastName FROM Participant__c WHERE Name = :participantNumber];
        }
        
        public Event__c getEventName(String eventCode){
            return [SELECT Id, Name FROM Event__c WHERE Event_Id__c =: eventCode];
        }
        /*******************************************************************************************
        * @name: getEvent
        * @author: ??
        * @created: ??
        * @description:
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -----------------------------
        * @version    1.0   ??           		??                    ??
        *             2.0   12-07-2022          Edison Crisostomo     [CCN-EVE-1841-DV] - Updated to include CompanyLogoURL
        *             3.0   08-25-2022          Mel Mallorca          [CCN-EVE-2012-DV] Add field values
        *******************************************************************************************/
        public Event__c getEvent(String eventCode){
            return [SELECT Name,
                    Subtitle__c,
                    Event_Id__c,
                    Hero_Image_URL__c,
                    Campaign_Logo_URL__c,
                    Company_Logo_URL__c,
                    Description__c,
                    Contact_Us_Tag_Line__c,
                    Contact_Us_Message__c,
                    Location__r.BillingStreet,
                    Location__r.BillingCity, 
                    Location__r.BillingPostalCode,
                    Location__r.BillingState,
                    Location__r.BillingCountry,
                    Location__r.Name,
                    OwnerId,
                    Start_Date_Time__c, 
                    Contact_Us_User__c,
                    Time_Zone__c,
                    Status__c,
                    End_Date_Time__c,
                    Home_Page_Title__c,
                    Sessions_Page_Title__c,
                    Materials_Page_Title__c,
                    Issue_Tracker_Page_Title__c,
                    Parking_Lot_Page_Title__c,
                    Survey_Page_Title__c,
                    Contact_Us_Page_Title__c,
                    Learn_More_Page_Title__c,
                    Event_Pages__c,
                    Personalized_Event_Page_Login_Button__c,
                    Sessions_with_General_Materials__c,
                    Event_Page_URL__c, 
                    Show_To_Links__c,
                    //Start [CCN-EVE-2012-DV] Add field values
                    Sessions_Calendar_Page_URL__c, 
                    Add_Session_Calendar_to_Summary_Page__c    
                    //End [CCN-EVE-2012-DV] Add field values
                    FROM Event__c WHERE Event_Id__c =: eventCode];
        }

        /*******************************************************************************************
        * @name: getEvents
        * @author: ??
        * @created: ??
        * @description:
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -----------------------------
        * @version    1.0   ??           		??                    ??
        *             2.0   12-07-2022          Edison Crisostomo     [CCN-EVE-1841-DV] - Updated to include CompanyLogoURL
        *             3.0   30-08-2022          Mel Christian Mallorca[CCN-EVE-2108-DV] - Add isActive criteria
        *             4.0   28-11-2022          Mel Christian Mallorca[CCN-EVE-2173-DV] - Added param for event types/names filter
        *******************************************************************************************/
        //Start [CCN-EVE-2173-DV] Added param for Event Type and Event Name, Update Query MelMallorca Nov262022
        public List<Event__c> getEvents(String campaignId, List<String> eventType, List<String> eventName){
            
            List<Event__c> sObjectList;
            if(!eventType.isEmpty() && !eventName.isEmpty()){
                sObjectList = [SELECT Name, Subtitle__c, Event_Id__c, Hero_Image_URL__c, Campaign_Logo_URL__c, Company_Logo_URL__c, Description__c, Contact_Us_Tag_Line__c, Contact_Us_Message__c, Location__r.BillingStreet, Location__r.BillingCity, Location__r.BillingPostalCode, Location__r.BillingState, Location__r.BillingCountry, Location__r.Name, 
                               OwnerId, Start_Date_Time__c, Contact_Us_User__c, Time_Zone__c, Status__c, End_Date_Time__c, Home_Page_Title__c, Sessions_Page_Title__c, Materials_Page_Title__c, Issue_Tracker_Page_Title__c, Parking_Lot_Page_Title__c, Survey_Page_Title__c, Contact_Us_Page_Title__c, Learn_More_Page_Title__c, Event_Pages__c,
                               Personalized_Event_Page_Login_Button__c, Sessions_with_General_Materials__c, Event_Page_URL__c, Show_To_Links__c, Sessions_Calendar_Page_URL__c, Add_Session_Calendar_to_Summary_Page__c
                               FROM  Event__c
                               WHERE Campaign__c =: campaignId
                               AND Event_Type__c IN: eventType
                               AND Name IN: eventName
                               AND IsActive__c = true ORDER BY Start_Date_Time__c ASC, End_Date_Time__c ASC, Name ASC];
            }
            else if( !eventType.isEmpty()){
                sObjectList = [SELECT Name, Subtitle__c, Event_Id__c, Hero_Image_URL__c, Campaign_Logo_URL__c, Company_Logo_URL__c, Description__c, Contact_Us_Tag_Line__c, Contact_Us_Message__c, Location__r.BillingStreet, Location__r.BillingCity, Location__r.BillingPostalCode, Location__r.BillingState, Location__r.BillingCountry, Location__r.Name, 
                               OwnerId, Start_Date_Time__c, Contact_Us_User__c, Time_Zone__c, Status__c, End_Date_Time__c, Home_Page_Title__c, Sessions_Page_Title__c, Materials_Page_Title__c, Issue_Tracker_Page_Title__c, Parking_Lot_Page_Title__c, Survey_Page_Title__c, Contact_Us_Page_Title__c, Learn_More_Page_Title__c, Event_Pages__c,
                               Personalized_Event_Page_Login_Button__c, Sessions_with_General_Materials__c, Event_Page_URL__c, Show_To_Links__c, Sessions_Calendar_Page_URL__c, Add_Session_Calendar_to_Summary_Page__c
                               FROM  Event__c
                               WHERE Campaign__c =: campaignId
                               AND Event_Type__c IN: eventType
                               AND IsActive__c = true ORDER BY Start_Date_Time__c ASC, End_Date_Time__c ASC, Name ASC];
            }
            else if( !eventName.isEmpty()){
                sObjectList = [SELECT Name, Subtitle__c, Event_Id__c, Hero_Image_URL__c, Campaign_Logo_URL__c, Company_Logo_URL__c, Description__c, Contact_Us_Tag_Line__c, Contact_Us_Message__c, Location__r.BillingStreet, Location__r.BillingCity, Location__r.BillingPostalCode, Location__r.BillingState, Location__r.BillingCountry, Location__r.Name, 
                               OwnerId, Start_Date_Time__c, Contact_Us_User__c, Time_Zone__c, Status__c, End_Date_Time__c, Home_Page_Title__c, Sessions_Page_Title__c, Materials_Page_Title__c, Issue_Tracker_Page_Title__c, Parking_Lot_Page_Title__c, Survey_Page_Title__c, Contact_Us_Page_Title__c, Learn_More_Page_Title__c, Event_Pages__c,
                               Personalized_Event_Page_Login_Button__c, Sessions_with_General_Materials__c, Event_Page_URL__c, Show_To_Links__c, Sessions_Calendar_Page_URL__c, Add_Session_Calendar_to_Summary_Page__c
                               FROM  Event__c
                               WHERE Campaign__c =: campaignId
                               AND Name IN: eventName
                               AND IsActive__c = true ORDER BY Start_Date_Time__c ASC, End_Date_Time__c ASC, Name ASC];
            }
            else{
                sObjectList = [SELECT Name,
                        Subtitle__c,
                        Event_Id__c,
                        Hero_Image_URL__c,
                        Campaign_Logo_URL__c,
                        Company_Logo_URL__c,
                        Description__c,
                        Contact_Us_Tag_Line__c,
                        Contact_Us_Message__c,
                        Location__r.BillingStreet,
                        Location__r.BillingCity, 
                        Location__r.BillingPostalCode,
                        Location__r.BillingState,
                        Location__r.BillingCountry,
                        Location__r.Name,
                        OwnerId,
                        Start_Date_Time__c, 
                        Contact_Us_User__c,
                        Time_Zone__c,
                        Status__c,
                        End_Date_Time__c,
                        Home_Page_Title__c,
                        Sessions_Page_Title__c,
                        Materials_Page_Title__c,
                        Issue_Tracker_Page_Title__c,
                        Parking_Lot_Page_Title__c,
                        Survey_Page_Title__c,
                        Contact_Us_Page_Title__c,
                        Learn_More_Page_Title__c,
                        Event_Pages__c,
                        Personalized_Event_Page_Login_Button__c,
                        Sessions_with_General_Materials__c ,
                        Event_Page_URL__c,           
                        Show_To_Links__c,   
                        //Start [CCN-EVE-2012-DV] Add field values
                        Sessions_Calendar_Page_URL__c, 
                        Add_Session_Calendar_to_Summary_Page__c   
                        //End [CCN-EVE-2012-DV] Add field values
                        FROM Event__c WHERE Campaign__c =: campaignId AND IsActive__c = TRUE
                        ORDER BY Start_Date_Time__c ASC, End_Date_Time__c ASC, Name ASC];
            }
            return sObjectList;
            //End [CCN-EVE-2173-DV] MelMallorca Nov262022
        }

        /*******************************************************************************************
        * @name: getSorted
        * @author: ??
        * @created: ??
        * @description:
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -----------------------------
        * @version    1.0   ??           		??                    ??
        *             2.0   12-07-2022          Edison Crisostomo     [CCN-EVE-1841-DV] - Updated to include CompanyLogoURL
        *             3.0   08-25-2022          Mel Mallorca          [CCN-EVE-2012-DV] Add field values
        *             4.0   28-11-2022          Mel Christian Mallorca[CCN-EVE-2173-DV] - Added param for event types/names filter
        *******************************************************************************************/
        public List<Event__c> getSortedEvents(String campaignId, String sortType, List<String> eventTypes, List<String> eventNames){
            String etFilter = '';
            String eNFilter = '';
            for (Integer i = 0; i < eventTypes.size(); i++) {
                if(i==eventTypes.size()-1){etFilter += '\''+eventTypes[i]+'\'';}
                else{etFilter += '\''+eventTypes[i]+'\',';}
            }
            for (Integer i = 0; i < eventNames.size(); i++) {
                if(i==eventNames.size()-1){eNFilter += '\''+eventNames[i]+'\'';}
                else{eNFilter += '\''+eventNames[i]+'\',';}
            }
            String eventTypeFilter  = (eventTypes.size() > 0? ' AND Event_Type__c' + ' IN ('+ etFilter +')': '');
            String eventNameFilter  = (eventNames.size() > 0? ' AND Name' + ' IN ('+ eNFilter +')': '');
            
            //Start [CCN-EVE-2012-DV] Add field values
            String soqlQuery = 'SELECT Name, Subtitle__c, Event_Id__c, Hero_Image_URL__c, Campaign_Logo_URL__c, Company_Logo_URL__c, Description__c, '
                + 'Contact_Us_Tag_Line__c, Contact_Us_Message__c, Location__r.BillingStreet, Location__r.BillingCity, Location__r.BillingPostalCode,' 
                + 'Location__r.BillingState, Location__r.BillingCountry, Location__r.Name, OwnerId, Start_Date_Time__c,  Contact_Us_User__c, Time_Zone__c,'
                + 'Status__c, End_Date_Time__c, Home_Page_Title__c, Sessions_Page_Title__c, Materials_Page_Title__c, Issue_Tracker_Page_Title__c, Parking_Lot_Page_Title__c, '
                + 'Survey_Page_Title__c, Contact_Us_Page_Title__c,  Learn_More_Page_Title__c, Event_Pages__c,  Personalized_Event_Page_Login_Button__c, Sessions_with_General_Materials__c , '
                + 'Event_Page_URL__c,Show_To_Links__c, Sessions_Calendar_Page_URL__c, Add_Session_Calendar_to_Summary_Page__c FROM Event__c WHERE IsActive__c = TRUE AND Campaign__c = \'' + campaignId + '\' '
                + (eventTypeFilter != null ? eventTypeFilter : '')
                + (eventNameFilter != null ? eventNameFilter : '')
                + 'ORDER BY ' + sortType; 
            //End [CCN-EVE-2012-DV] Add field values
            return database.query(soqlQuery);
        }
        
        public String getUserTimezone(Id userId){
            return [SELECT ID, TimeZoneSidKey FROM User WHERE ID = :userId LIMIT 1][0].TimeZoneSidKey;
        }

        /******************************************************************************    
        * Changes (version)
        *            No.  Date(dd-mm-yyy) Author            Description
        *           ----  ---------   --------------------  -----------------------------
        * @version   2.0  10-06-2022   VonPernicia          [CCN-1757] query to get time zone for the list of users
        ******************************************************************************/
        public List<User> getUserTimezone(Set<Id> userIds){
            return [SELECT ID, TimeZoneSidKey FROM User WHERE ID in: userIds];
        }
        
        public List<Event_Role__c> getEventRole(Id eventId){
            return [SELECT Contact__r.FirstName ,
                    Contact__r.lastName,
                    Contact__r.Title,
                    Contact__r.Profile_Description__c,
                    Contact__r.Profile_Picture_URL__c 
                    FROM Event_Role__c WHERE Event__r.Id = :eventId AND Show_in_Event_Site__c = true AND Role__c = 'Speaker'];
        }
        
        /*******************************************************************************************
        * @name: getEvents
        * @author: Leif Erickson de Gracia
        * @created: Sept 5, 2023
        * @description: CCN-EVE-3304-DV
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -------------------------------
        * @version    1.0   05-09-2023        Leif Erickson de Gracia   Initial Version
        *********************************************************************************************/
        public List < Event__c > getEvents(String campaignId, String additionalFieldsToQuery) {
            String strQuery = 'SELECT Id, Name, Registration_Tag_Line__c, Registration_Message__c, Registration_Fields_JSON__c ' + additionalFieldsToQuery + 'FROM Event__c WHERE Event_Id__c =: campaignId';
            return Database.query(strQuery);
        }        
    }
}