/**
 * Coverage by ParkingLotTriggerHander_Test.cls
 * Modified By: 7/17/2023 - Rex David - CCN-EVE-3237-DV_ParkingLotCategoryExpansion
 */
public with sharing class ParkingLotTriggerHandler extends TriggerHandler{
    protected override void beforeInsert(List<SObject> newRecords) {
        updateEmail((List<Parking_Lot__c>) newRecords);
    }

    protected override void beforeUpdate(Map<Id, SObject> updatedRecordsMap, Map<Id, SObject> oldRecordsMap) {
        updateEmail((List<Parking_Lot__c>) updatedRecordsMap.values());
        updateFirstModifiedDate((Map<Id, Parking_Lot__c>)updatedRecordsMap, (Map<Id, Parking_Lot__c>) oldRecordsMap);
        updateParkingLotToClosed((Map<Id, Parking_Lot__c>)updatedRecordsMap, (Map<Id, Parking_Lot__c>) oldRecordsMap);
    }

    protected override void afterInsert(Map<Id, SObject> newRecordsMap) {
        new WithoutShare().sendEmail(
            createEmailFromTemplate((List<Parking_Lot__c>)newRecordsMap.values(), 'Open')
        );
    }
    protected override void afterUpdate(Map<Id, SObject> updatedRecordsMap, Map<Id, SObject> oldRecordsMap) {
        List<Parking_Lot__c> updatedLots = getUpdatedRecordsWithChangedFields(new List<SObjectField>{Parking_Lot__c.Status__c,Parking_Lot__c.Assigned_To__c});
        List<Parking_Lot__c> closedLots = new List<Parking_Lot__c>();
        List<Parking_Lot__c> assignedLots = new List<Parking_Lot__c>(); //7-17-2023 CCN-EVE-3237-DV_ParkingLotCategoryExpansion - Rex David
        final String closed = 'Closed'; 
        for (Parking_Lot__c lot : updatedLots){
            if (lot.Status__c != closed && lot.Assigned_To__c != NULL) assignedLots.add(lot); //7-17-2023 CCN-EVE-3237-DV_ParkingLotCategoryExpansion - Rex David
            if (lot.Status__c != closed){ continue; }
            closedLots.add(lot);
        }
        
        if(closedLots.size()>0){
            // commented before because user receives duplicate email in prod, duplicate of email alert
            /**Start of CCN-463: RLugpatan 27.Mar.2023 - Uncommented the code below after deactivating "WF Rule: Closed Parking Lot Notification" **/
            new WithoutShare().sendEmail(createEmailFromTemplate(closedLots, closed));
		    /** End of CCN-463 **/
        }
        //7-17-2023 CCN-EVE-3237-DV_ParkingLotCategoryExpansion - Rex David
        if(assignedLots.size()>0){
            new WithoutShare().sendEmail(createEmailFromTemplate(assignedLots, 'Assigned'));
        }
        
    }

    private List<Messaging.SingleEmailMessage> createEmailFromTemplate(List<Parking_Lot__c> emailSendable, String action){
        
        WithoutShare elevatedContext = new WithoutShare();
        List<Event__c> events = elevatedContext.getEvent(emailSendable);
        Map<String, Compass_Setting__c> configMap = elevatedContext.getConfigMap(events, emailSendable);
        Map<String, String> eventIdOrgWideAddress = getEventOrgWideEmail(events);
        Map<String, String> eventIdParkingLot = getEventIdEmailUser(events);
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        final Boolean sendToRaisedBy = action == 'Closed';
        final Boolean sendToAssignedTo = action == 'Assigned';
        final String userPrefix = '005';
        for(Parking_Lot__c lot : emailSendable){
            String sendToField = '';
            String templateId = '';
            //This if statement Sends email when a first modified record 
            if(SendEmail){
                sendToField = lot.Raised_By__c;
            	templateId = configMap.get(lot.Id).Email_Template_First_Modified_Parking__c;
            }else if(action == 'Open'){//7-17-2023 CCN-EVE-3237-DV_ParkingLotCategoryExpansion - Rex David - Replaced --> !SendToField.equalsIgnoreCase('Closed')){
                sendToField = eventIdParkingLot.get(lot.Event__c);
                templateId = configMap.get(lot.Id).Email_Template_Parking_Lot_Open__c;
            }
            
            if (sendToRaisedBy){
                sendToField = lot.Raised_By__c;
                templateId = configMap.get(lot.Id).Email_Template_Parking_Lot_Closed__c;
            }
            if(String.isNotBlank(templateId) && String.isNotBlank(sendToField)){ //7-17-2023 CCN-EVE-3237-DV_ParkingLotCategoryExpansion - Rex David - Added condition
                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(
                    templateId, 
                    sendToField,
                    lot.Id
                );
                mail.setTargetObjectId(sendToField);
                mail.setSaveAsActivity(!sendToField.startsWith(userPrefix));
                mail.setOrgWideEmailAddressId((Id) eventIdOrgWideAddress.get(lot.Event__c));
                emails.add(mail);
            }
    
            //7-17-2023 CCN-EVE-3237-DV_ParkingLotCategoryExpansion - Rex David - Start
            if (sendToAssignedTo){
                String assignedSendToField = '';
                String assignedTemplateId = '';
                assignedSendToField = lot.Assigned_To__c;
                assignedTemplateId = configMap.get(lot.Id).Email_Template_Parking_Lot_Assigned__c;
                // Logic to send Email
                Messaging.SingleEmailMessage assignedMail = Messaging.renderStoredEmailTemplate(
                    assignedTemplateId, 
                    assignedSendToField,
                    lot.Id
                );
                assignedMail.setTargetObjectId(assignedSendToField);
                assignedMail.setSaveAsActivity(!assignedSendToField.startsWith(userPrefix));
                assignedMail.setOrgWideEmailAddressId((Id) eventIdOrgWideAddress.get(lot.Event__c));
                emails.add(assignedMail);
            }
            //7-17-2023 CCN-EVE-3237-DV_ParkingLotCategoryExpansion - Rex David - End
        }
        
        return emails;
    }

    private Map<String, String> getEventOrgWideEmail(List<Event__c> events){
        Map<String, String> eventOrgWideEmail = new Map<String, String>();
        for (Event__c evt : events){
            eventOrgWideEmail.put(evt.Id, evt.Email_Sender_Id__c);
        }
        return eventOrgWideEmail;
    }

    private Map<String, String> getEventIdEmailUser(List<Event__c> events){
        Map<String, String> eventIdParkingLotUser = new Map<String, String>();
        for (Event__c evt : events){
            String sendToUser = evt.OwnerId;
            if (evt.Parking_Lot_User__r?.Email != null){
                sendToUser = evt.Parking_Lot_User__c;
            }
            eventIdParkingLotUser.put(evt.Id, sendToUser);
        }
        return eventIdParkingLotUser;
    }
    /*
     * Author: Victory Bolante 
     * Date Created: 08-16-2021
     * Description: This is to update the First Modified Date of the record on its first update.
     */ 
    private Boolean SendEmail = false;
    private void updateFirstModifiedDate(Map<Id, Parking_Lot__c> updatedParkingLotRecordMap, Map<Id, Parking_Lot__c> oldParkingLotRecordMap){
        
        for(Parking_Lot__c ParkingLot: updatedParkingLotRecordMap.values()){
            if(oldParkingLotRecordMap.get(ParkingLot.Id) != ParkingLot){
                if(oldParkingLotRecordMap.get(ParkingLot.Id).First_Modified_Date__c == null && ParkingLot.First_Modified_Date__c == null){
                    ParkingLot.First_Modified_Date__c = System.now();
                    SendEmail=true;
                }
            }
        }
        if(SendEmail){
            /*
            new WithoutShare().sendEmail(
               createEmailFromTemplate((List<Parking_Lot__c>)updatedParkingLotRecordMap.values(), 'Open')
           ); 
			*/
        }
    }
    /*
     * Author: Victory Bolante 
     * Date Created: 08-16-2021
     * Description: This is to update the Closed Date of the record on its close event.
     */ 
    private void updateParkingLotToClosed(Map<Id, Parking_Lot__c> updatedParkingLotRecordMap, Map<Id, Parking_Lot__c> oldParkingLotRecordMap){
        for(Parking_Lot__c ParkingLot: updatedParkingLotRecordMap.values()){
            if(String.isNotEmpty(oldParkingLotRecordMap.get(ParkingLot.Id).Status__c)  && String.isNotEmpty(ParkingLot.Status__c)){
                if(!oldParkingLotRecordMap.get(ParkingLot.Id).Status__c.equals('Closed') && ParkingLot.Status__c.equals('Closed')){
                    ParkingLot.Closed_Date__c	= System.now();
                }
            }
        }
    }

    private void updateEmail(List<Parking_Lot__c> newList){
        Map<Id,Event__c> eventMap = new Map<Id,Event__c>();
        if(FlsUtils.isAccessible('Event__c', new List<String>{'OwnerId','Parking_Lot_User__c','Event_Id__c','Email_Logo_URL__c'}) 
                && FlsUtils.isAccessible('Contact', new List<String>{'Email'})){
            eventMap = new Map<Id,Event__c>(new WithoutShare().getEvent(newList));  
        }
        for(Parking_Lot__c parkingLot : newList){
            if(eventMap.get(parkingLot.Event__c)?.Parking_Lot_User__r?.Email != null && eventMap.get(parkingLot.Event__c)?.Parking_Lot_User__r?.Email != ''){
                parkingLot.Tech_Notification_Email__c =  eventMap.get(parkingLot.Event__c)?.Parking_Lot_User__r?.Email;
            }
            else{
                parkingLot.Tech_Notification_Email__c =  eventMap.get(parkingLot.Event__c)?.Owner?.Email;
            }
            parkingLot.Email_Logo_URL__c = eventMap.get(parkingLot.Event__c)?.Email_Logo_URL__c;
            parkingLot.Parking_Lot_Page_URL__c =  getCommunityURL('Compass') + '/s/parking-lot?id=' + eventMap.get(parkingLot.Event__c)?.Event_Id__c;
        }
    }
     
    private String getCommunityURL(string communityName){
        if (!Test.isRunningTest()){
            Network myNetwork = [SELECT Id FROM Network WHERE Name = :communityName WITH SECURITY_ENFORCED];
            ConnectApi.Community  myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
            return myCommunity.siteUrl ;
        } else {
            return 'some random url';
        }
    }

    private without sharing class WithoutShare {
        public List<Event__c> getEvent(List<Parking_Lot__c> lots){
            Set<Id> eventIds = new Set<Id>();
            for(Parking_Lot__c lot : lots){
                eventIds.add(lot.Event__c);
            }
            return [SELECT Id,
                Event_Id__c,
                Email_Logo_URL__c,
                Email_Sender_Id__c,
                Parking_Lot_User__c,
                Parking_Lot_User__r.Email,
                OwnerId,
                Owner.Email,
                Compass_Setting__c,
                Compass_Setting__r.Email_Template_Parking_Lot_Closed__c,
                Compass_Setting__r.Email_Template_Parking_Lot_Open__c,
                Compass_Setting__r.Email_Template_First_Modified_Parking__c,
                Compass_Setting__r.Email_Template_Parking_Lot_Assigned__c
                FROM Event__c 
                WHERE Id IN: eventIds
            ];
        }

        public Map<String, Compass_Setting__c> getConfigMap(List<Event__c> events, List<Parking_Lot__c> lots){
            Compass_Setting__c defaultSetting = [
                SELECT ID,
                Email_Template_Parking_Lot_Closed__c,
                Email_Template_Parking_Lot_Open__c,
                Email_Template_First_Modified_Parking__c,
                Email_Template_Parking_Lot_Assigned__c
                FROM Compass_Setting__c
                WHERE Default__c = TRUE
                LIMIT 1
            ];
            Map<Id, Compass_Setting__c> eventSettingMap = new Map<Id, Compass_Setting__c>();
            for (Event__c evt : events){
                if (evt.Compass_Setting__r?.Email_Template_Parking_Lot_Closed__c != null 
                || evt.Compass_Setting__r?.Email_Template_Parking_Lot_Open__c != null
                || evt.Compass_Setting__r?.Email_Template_Parking_Lot_Assigned__c != null){
                    eventSettingMap.put(evt.Id, evt.Compass_Setting__r);
                    continue;
                }
                eventSettingMap.put(evt.Id, defaultSetting);
            }
            Map<String, Compass_Setting__c> configMap = new Map<String, Compass_Setting__c>();
            for (Parking_Lot__c lot : lots){
                configMap.put(lot.Id, eventSettingMap.get(lot.Event__c));
            }
            return configMap;
        }

        public void sendEmail(List<Messaging.SingleEmailMessage> emails){
            if(!Test.isRunningTest()){
                Messaging.sendEmail(emails);
            }
            system.debug('It went here sending email>>>');
        }
    }
}