/*******************************************************************************************
  * @name: EventConfirmationResponseController
  * @author: Paolo Quiambao
  * @created: 26-08-2021
  * @description: Controller for Confirm/Delete upon clicking the button from the Event Confirmation Template Email
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *             No.   Date(dd-mm-yyy)   Author                Description
  *             ----  ---------------   --------------------  ---------------------------------
  * @version    1.0   26-08-2021        Paolo Quiambao        Initial Creation
  * 			2.0	  30-04-2022		Paolo Quiambao		  Enhance logic to accept multiple Session Participant Ids
  * @version    1.0   23-06-2022         Von Pernicia         [CCN-EVE-2390-DV] added sObjName and condition to identify which object is being updated
  *********************************************************************************************/
public class EventConfirmationResponseController {
    public String sessionIds {get;set;} // Updated by PaoloQuiambao [ccneve1216dv] April302022
    public String response {get;set;}
    public List<String> sessionIdList {get;set;} // Updated by PaoloQuiambao [ccneve1216dv] April302022
    
    public void updateSessionParticipantStatus() {
        sessionIds = ApexPages.currentPage().getParameters().get('id');
        sessionIdList = sessionIds.split(' ');
        response = ApexPages.currentPage().getParameters().get('response');
        
        if(!sessionIdList.isEmpty()) {

            Id myId = sessionIdList[0];
            String sObjName = myId.getSObjectType().getDescribe().getName();
            
            if (sObjName == 'Session_Participant__c') {

                List<Session_Participant__c> sessionParticipantListToUpdate = new List<Session_Participant__c>(); // Updated by PaoloQuiambao [ccneve1216dv] April302022

                try {
                    // Updated by PaoloQuiambao [ccneve1216dv] April302022
                    for(Session_Participant__c sp : [SELECT Id, Status__c FROM Session_Participant__c WHERE Id IN :sessionIdList]) {
                        sp.Status__c = response;
                        sessionParticipantListToUpdate.add(sp);
                    }
                }
                catch(Exception err) {
                    System.Debug('TRY-CATCH-Exception-->' + err);
                }
                
                try {
                    if(!sessionParticipantListToUpdate.isEmpty()) {
                        update sessionParticipantListToUpdate;
                    }
                }
                catch(Exception err) {
                    System.Debug('TRY-CATCH-Exception-->' + err);
                }
            } else if (sObjName == 'Internal_Resource_Session__c') {

                List<Internal_Resource_Session__c> resourceSessionListToUpdate = new List<Internal_Resource_Session__c>();

                try {
                    for(Internal_Resource_Session__c sp : [SELECT Id, Resource_Session_Status__c FROM Internal_Resource_Session__c WHERE Id IN :sessionIdList]) {
                        sp.Resource_Session_Status__c = response;
                        resourceSessionListToUpdate.add(sp);
                    }
                }
                catch(Exception err) {
                    System.Debug('TRY-CATCH-Exception-->' + err);
                }
                
                try {
                    if(!resourceSessionListToUpdate.isEmpty()) {
                        update resourceSessionListToUpdate;
                    }
                }
                catch(Exception err) {
                    System.Debug('TRY-CATCH-Exception-->' + err);
                }
            }
            
        }
    }
}