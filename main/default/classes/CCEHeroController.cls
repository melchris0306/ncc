public with sharing class CCEHeroController {

    private static WithoutSharingClass withoutShare = new WithoutSharingClass();

    @AuraEnabled
    public static CCEEventWrapper getEventDetails(String eventId) {
        try {
            Campaign campaignRecord = new Campaign();
        
            CCEEventWrapper eventRecord = new CCEEventWrapper();
            if(FlsUtils.isAccessible('Campaign', new List<String>{'Name','Subtitle__c','Event_Id__c','Hero_Image_URL__c','Campaign_Logo_URL__c',
                'Description__c','Contact_Us_Tag_Line__c','Contact_Us_Message__c', 'OwnerId', 'Start_Date_Time__c','Contact_Us_User__c',
                'Time_Zone__c','Status','End_Date_Time__c'}) && FlsUtils.isAccessible('Account', new List<String>{'BillingStreet','BillingCity',
                'BillingPostalCode','BillingState','BillingCountry'})){
    
                campaignRecord =  withoutShare.getCampaign(eventId);
            }
            
            // If Contact Us User is populated then use this user's timezone, otherwise use campaign owner's timezone
            String timezone;
            if(FlsUtils.isAccessible('User', new List<String>{'TimeZoneSidKey'})){
                if (campaignRecord.Contact_Us_User__c != null){
                    timezone = withoutShare.getUserTimezone(campaignRecord.Contact_Us_User__c);
                } else {
                    timezone = withoutShare.getUserTimezone(campaignRecord.OwnerId);
                }
            }
            Event__c eventRec = new Event__c();
            eventRec = withoutShare.getEvent(eventId);
            eventRecord.EventExternalId = campaignRecord.Event_Id__c;
            eventRecord.title = campaignRecord.Name;
            eventRecord.subtitle = campaignRecord.Subtitle__c;
            eventRecord.HeroUrl = campaignRecord.Hero_Image_URL__c;
            eventRecord.CampaignLogoUrl= campaignRecord.Campaign_Logo_URL__c;
            eventRecord.Street = campaignRecord.Location__r.BillingStreet;
            eventRecord.City = campaignRecord.Location__r.BillingCity;
            eventRecord.PostalCode = campaignRecord.Location__r.BillingPostalCode;
            eventRecord.State = campaignRecord.Location__r.BillingState;
            eventRecord.Country = campaignRecord.Location__r.BillingCountry;
            eventRecord.Description = campaignRecord.Description__c; 
            eventRecord.contactTag = campaignRecord.Contact_Us_Tag_Line__c; 
            eventRecord.contactMessage = campaignRecord.Contact_Us_Message__c; 
            String strTZone = [SELECT Id, TimeZoneSidKey FROM Organization].TimeZoneSidKey;
            //eventRecord.StartDateTime = campaignRecord.Start_Date_Time__c.format('MMMM d, yyyy h:mm a', strTZone) + ' ' + campaignRecord.Time_Zone__c;
            //eventRecord.EndDateTime = campaignRecord.End_Date_Time__c.format('MMMM d, yyyy h:mm a', strTZone) + ' ' + campaignRecord.Time_Zone__c;
            eventRecord.StartDateTime = system.now()+ '';
            eventRecord.EndDateTime = system.now()+ '';
            eventRecord.CampaignStatus = campaignRecord.Status;
            eventRecord.surveyPageTitle = eventRec.Survey_Page_Title__c;
            eventRecord.materialsPageTitle = eventRec.Materials_Page_Title__c;
            return eventRecord;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getStackTraceString());    
        }
    }
    
    @AuraEnabled
    public static CCEEventWrapper getEventSession(String eventId) {
        Campaign campaignRecord = new Campaign();
        CCEEventWrapper eventRecord = new CCEEventWrapper();
        List<Campaign> campaignList = new List<Campaign>();
        if(FlsUtils.isAccessible('Campaign', new List<String>{'OwnerId','Contact_Us_User__c'})){
            campaignRecord = withoutShare.getCampaignForContactUsUser(eventId);
        }

        // If Contact Us User is populated then use this user's timezone, otherwise use campaign owner's timezone
        String timezone;
        if(FlsUtils.isAccessible('User', new List<String>{'TimeZoneSidKey'})){
            if (campaignRecord.Contact_Us_User__c != null){
                timezone = withoutShare.getUserTimezone(campaignRecord.Contact_Us_User__c);
            } else {
                timezone = withoutShare.getUserTimezone(campaignRecord.OwnerId);
            }
        }

        String strTZone = [SELECT Id, TimeZoneSidKey FROM Organization LIMIT 1].TimeZoneSidKey;
        if(FlsUtils.isAccessible('Campaign', new List<String>{'Name','Subtitle__c','Event_Id__c','Start_Date_Time__c','End_Date_Time__c','Description__c','Time_Zone__c'})){
            campaignList = withoutShare.getCampaigns(campaignRecord.Id);
        }

        eventRecord.SessionList = new List<CCEEventWrapper.SessionDetail>();
        
        String SessionDateMatch = '';
        
        for(Campaign CampaignRec : campaignList){
            
            String SessionDateMatchCompare = '';
            if (CampaignRec.Start_Date_Time__c != null){
                SessionDateMatchCompare = CampaignRec.Start_Date_Time__c.format('MMM d', strTZone);
            }
            
            if(SessionDateMatch != SessionDateMatchCompare){
                CCEEventWrapper.SessionDetail sessionRecHeader = new CCEEventWrapper.SessionDetail();
                sessionRecHeader.isHeader = true;
                sessionRecHeader.SessionDate = CampaignRec.Start_Date_Time__c.format('EEEE, MMMM d, yyyy');
                sessionRecHeader.SessionMonth = String.valueOf(CampaignRec.Start_Date_Time__c.month());
                eventRecord.SessionList.add(sessionRecHeader);
                SessionDateMatch = SessionDateMatchCompare;
            }
            
            CCEEventWrapper.SessionDetail sessionRec = new CCEEventWrapper.SessionDetail();
            sessionRec.isHeader = false;
            sessionRec.title  = CampaignRec.Name;
            sessionRec.subtitle = CampaignRec.Subtitle__c;
            if (CampaignRec.Start_Date_Time__c != null && CampaignRec.End_Date_Time__c != null){
                sessionRec.SessionDate = CampaignRec.Start_Date_Time__c.format('MMM d, yyyy', strTZone);
                sessionRec.StartTime = CampaignRec.Start_Date_Time__c.format('h:mm a', strTZone);
                sessionRec.EndTime = CampaignRec.End_Date_Time__c.format('h:mm a', strTZone);
                sessionRec.TimeZone = CampaignRec.Time_Zone__c;
            }
            
            eventRecord.SessionList.add(sessionRec);
        }

        return eventRecord;
    }
    
    @AuraEnabled
    public static List<CCESpeakerWrapper> getSpeakerDetails(String eventId) {
        Campaign campaignRecord = new Campaign();
        List<Event_Role__c> eventRoleList = new List<Event_Role__c>();
        List<CCESpeakerWrapper> speakerList = new List<CCESpeakerWrapper>();

        if(FlsUtils.isAccessible('User', new List<String>{'Name'})){
            campaignRecord = withoutShare.getCampaignName(eventId);
        }

        if(FlsUtils.isAccessible('Contact', new List<String>{'FirstName','lastName','Title','Profile_Description__c','Profile_Picture_URL__c'})){
            eventRoleList = withoutShare.getEventRoles(campaignRecord.Id);
        }

        for(Event_Role__c er : eventRoleList){
            CCESpeakerWrapper speaker = new CCESpeakerWrapper();
            speaker.FirstName = er.Contact__r.FirstName;
            speaker.lastName = er.Contact__r.lastName;
            speaker.Title = er.Contact__r.Title;
            speaker.Description = er.Contact__r.Profile_Description__c;
            speaker.ProfilePicUrl = er.Contact__r.Profile_Picture_URL__c;
            speakerList.add(speaker);
        }
        
        return speakerList;
    } 
    
    @AuraEnabled
    // Create task for each request sent from the custom contact support form
    public static void createTask(String eventId, String firstname, String lastname, String email, String phone, String subject, String comments){
        if (String.isBlank(eventId) || String.isBlank(firstname) || String.isBlank(lastname) || String.isBlank(email) || String.isBlank(subject) || String.isBlank(comments)){
            return;
        } 
        
        CustomContactSupportFormHelper.createTaskHelper(eventId, firstname, lastname, email, phone, subject, comments);
    }

     //Needs inner class declared without sharing for guest users to retrieve relevant records
     private without sharing class WithoutSharingClass {
		
         public Event__c getEvent(String eventId){
            return [SELECT Name,
                    Subtitle__c,
                    Event_Id__c,
                    Materials_Page_Title__c,
                    Parking_Lot_Page_Title__c,
                    Survey_Page_Title__c FROM Event__c WHERE Event_Id__c =: eventId];
        }
         
        public List<Campaign> getCampaigns(String campaignId){
            return [SELECT Name, Subtitle__c, Event_Id__c, Start_Date_Time__c, End_Date_Time__c, Description__c, Time_Zone__c
                    FROM Campaign 
                    WHERE ParentId = :campaignId 
                    ORDER BY Start_Date_Time__c];
        }

        public Campaign getCampaignName(String eventId){
            return [SELECT Name FROM Campaign WHERE Event_Id__c =: eventId];
        }

        public Campaign getCampaignForContactUsUser(String eventId){
            return [SELECT Id, OwnerId, Contact_Us_User__c FROM Campaign WHERE Event_Id__c = :eventId];
        }

        public Campaign getCampaign(String eventId){

            List<Campaign> campaignList = [SELECT Name,Subtitle__c,Event_Id__c,Hero_Image_URL__c,Campaign_Logo_URL__c, Description__c,
                                                Contact_Us_Tag_Line__c,Contact_Us_Message__c,Location__r.BillingStreet,Location__r.BillingCity, 
                                                Location__r.BillingPostalCode,Location__r.BillingState,Location__r.BillingCountry,
                                                OwnerId,Start_Date_Time__c, Contact_Us_User__c,Time_Zone__c,Status,End_Date_Time__c
                                            FROM Campaign WHERE Event_Id__c =: eventId];
            
            if(!campaignList.isEmpty()){
                return campaignList[0];
            }

            return new Campaign();
        }

        public String getUserTimezone(Id userId){
            List<User> userList = [SELECT ID, TimeZoneSidKey FROM User WHERE ID = :userId LIMIT 1];
            
            if(!userList.isEmpty()){
                return userList[0].TimeZoneSidKey;
            }

            return '';
        }

        public List<Event_Role__c> getEventRoles(Id campaignId){
            return [SELECT Contact__r.FirstName ,
                        Contact__r.lastName,
                        Contact__r.Title,
                        Contact__r.Profile_Description__c,
                        Contact__r.Profile_Picture_URL__c 
                    FROM Event_Role__c 
                    WHERE Campaign__c = :campaignId
                        AND Show_in_Event_Site__c = true 
                        AND Role__c = 'Speaker'];
        }
    }
    
}