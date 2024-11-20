public with sharing class CCEventTriggerUtility {

    public class MyException extends Exception {}

    public static void generateOrdWideEmail(List < Event__c > eventList) {
        try {
            Compass_Setting__c compRec = new Compass_Setting__c();
            //Get the compass summary record for the Default Settings
            if (FlsUtils.isAccessible('Compass_Setting__c', new List < String > {
                    'Name',
                    'Email_Sender_Id__c'
                })) {
                compRec = [Select Id, Name, Email_Sender_Id__c, Email_Sender_Name__c FROM Compass_Setting__c WHERE Name =: 'Default Settings'
                    LIMIT 1
                ];
            }
            for (Event__c eventRec: eventList) {
                //if the email sender id of event is null, always copy from the default settings.
                if (eventRec.Email_Sender_Id__c == NULL) {
                    eventRec.Email_Sender_Id__c = compRec.Email_Sender_Id__c;
                }
                if (eventRec.Email_Sender_Name__c == NULL) {
                    eventRec.Email_Sender_Name__c = compRec.Email_Sender_Name__c;
                }
            }
        } catch (exception e) {

        }
    }

    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  25-11-2022   Xen Reyes            [CCN-LOG-2217-DV] Initial version.
    ******************************************************************************/
    public static void eventInternalLogistics(List <Event__c> eventList, Boolean isInsert) {
        try {
            
            Map<Id, Event__c> eventMap = new Map<Id, Event__c>(eventList);
            Set<Id> eventWithoutLogisticsId = new Set<Id>();
            List<Internal_Logistics__c> logisticsToInsert = new List<Internal_Logistics__c>();
            
            if(!isInsert){
                for(Event__c e : [SELECT Id, (SELECT Id FROM Internal_Logistics__r) FROM Event__c WHERE Id IN: eventList]){
                    if(e.Internal_Logistics__r.isEmpty()) eventWithoutLogisticsId.add(e.Id);
                }

                Map<Id, Set<String>> eventIdSessionMeetingLocationsMap = new Map<Id, Set<String>>();
                for(Event__c e : [SELECT Id, (SELECT Id, Meeting_URL__c FROM CC_Sessions__r WHERE IsActive__c = true) FROM Event__c WHERE Id IN: eventWithoutLogisticsId]){
                    Set<String> sessionMeetingLocations = new Set<String> ();
                    for(Session__c s : e.CC_Sessions__r){
                        if(s.Meeting_URL__c != null) sessionMeetingLocations.add(s.Meeting_URL__c);
                    }
                    eventIdSessionMeetingLocationsMap.put(e.Id, sessionMeetingLocations);
                }
                
                if(!eventWithoutLogisticsId.isEmpty()){
                    for(String eventId : eventWithoutLogisticsId){

                        String sessionMeetingLocationsCon = '';
                        Integer numberOfSessionMeetingLocations = 0;

                        if(eventIdSessionMeetingLocationsMap.containsKey(eventId)){
                            List<String> locationList = new List<String>(eventIdSessionMeetingLocationsMap.get(eventId));
                            locationList.sort();
                            sessionMeetingLocationsCon = String.join(locationList, ', ');
                            numberOfSessionMeetingLocations = eventIdSessionMeetingLocationsMap.get(eventId).size();
                        }

                        logisticsToInsert.add(new Internal_Logistics__c(Event_Name__c = eventId, 
                                                                        Campaign__c = eventMap.get(eventId).Campaign__c,
                                                                        Session_Locations__c = sessionMeetingLocationsCon,
                                                                        Number_of_Locations__c = numberOfSessionMeetingLocations));
                    }
                }
            } else {
                for(Event__c eventVar : eventList){
                    logisticsToInsert.add(new Internal_Logistics__c(Event_Name__c = eventVar.Id, 
                                                                    Campaign__c = eventVar.Campaign__c));
                }
            }

            insert logisticsToInsert;

        } catch (exception e) {
            throw new MyException(e);
        }
    }
}