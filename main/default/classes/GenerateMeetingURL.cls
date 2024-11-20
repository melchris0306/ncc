/**
 * Created by angelorivera on 7/10/20.
 *  @revision - Kyzer Buhay - Updated Objects from Campaign to Event__c
 */
public class GenerateMeetingURL {
    
    @AuraEnabled
    public static String generateMeetingURL(Id eventId, String strMeetingType){
        String strRet = '';
        String strMeetingLink ='';
        if(eventId != null){
            Event__c cmp  = [SELECT Id, Compass_Setting__c, Meeting_URL__c FROM Event__c WHERE Id=: eventId];
            Compass_Setting__c ccs = new Compass_Setting__c();
            ccs = getSettings(cmp.Compass_Setting__c);

            //generate meeting URL and update the field in campaign
            for(Meeting_Application__c ma : ccs.Online_Meetings__r){
                System.debug(LoggingLevel.DEBUG, '!@# Meeting Type: ' + ma.Type__c );
                if(ma.Name == strMeetingType){
                    if(strMeetingType == 'Amazon Chime'){
                        strMeetingLink = ma.Default_Meeting_URL__c+eventId;
                    }else{
                        strMeetingLink = ma.Default_Meeting_URL__c;
                    }
                    break;
                }
            }

            cmp.Meeting_URL__c = strMeetingLink;
            System.debug(LoggingLevel.DEBUG, '!@# Campaign Meeting URL: ' + cmp.Meeting_URL__c );
            try {
                Database.update(cmp);
                strRet = 'Meeting URL generated.';
            }catch (Exception ex){
                System.debug(LoggingLevel.DEBUG, '!@# ERROR IN INSERT: ' + ex.getMessage());
                strRet = 'Error generating meeting URL.';
            }
        }
        return strRet;
    }


    @AuraEnabled
    public static MeetingApplicationWrapper retrieveApplications(Id eventId){
        MeetingApplicationWrapper mWrapper = new MeetingApplicationWrapper();
        mWrapper.strReturn = '';
        if(eventId != null){
            Event__c cmp  = [SELECT Id, Compass_Setting__c FROM Event__c WHERE Id=: eventId];
            if(cmp.Compass_Setting__c != null){
                Compass_Setting__c ccs = new Compass_Setting__c();
                ccs = getSettings(cmp.Compass_Setting__c);
                mWrapper.mapMeetingApplicationsByType = new Map<String, List<Meeting_Application__c>>();
                mWrapper.setMeetingType = new Set<String>();
                mWrapper.setMeetingName = new Set<String>();
                for(Meeting_Application__c ma : ccs.Online_Meetings__r){
                    mWrapper.setMeetingType.add(ma.Type__c);
                    mWrapper.setMeetingName.add(ma.Name);

                    if(!mWrapper.mapMeetingApplicationsByType.containsKey(ma.Type__c)){
                        List<Meeting_Application__c> lApplications = new List<Meeting_Application__c>();
                        lApplications.add(ma);
                        mWrapper.mapMeetingApplicationsByType.put(ma.Type__c, lApplications);
                    }else{
                        mWrapper.mapMeetingApplicationsByType.get(ma.Type__c).add(ma);
                    }
                }
                mWrapper.strReturn = 'Success: Compass Setting Found.';
            }else{
                mWrapper.strReturn = 'Error: Missing Compass Settings.';
            }
        }
        return mWrapper;
    }

    public static Compass_Setting__c getSettings(Id settingId){
        return [SELECT Id, Name, Default__c,
                (SELECT Id, Name, Type__c, Default_Meeting_URL__c, Access_Key__c, Secret_Key__c,
                            Username__c, Password__c FROM Online_Meetings__r
                            WHERE Live__c = TRUE)
                    FROM  Compass_Setting__c
                WHERE Id =: settingId];
    }


    public class MeetingApplicationWrapper{
        @AuraEnabled public String strReturn {get; set;}
        @AuraEnabled public Set<String> setMeetingType {get; set;}
        @AuraEnabled public Set<String> setMeetingName {get; set;}
        @AuraEnabled public Map<String, List<Meeting_Application__c>> mapMeetingApplicationsByType {get; set;}
    }

}