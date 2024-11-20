/******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyyy)          Author                      Description
    *           ----  -----------------    -------------------       -----------------------------
    * @version   1.0  20-06-2022                   JC Espino        [CCN-EVE-3072-DV] Intial Version. Trigger: InternalResourceSessionTrigger.
    ******************************************************************************/
public class InternalResourceSessionTriggerHandler {

    static final String REGISTERED  = 'Registered';
    static final String CONFIRMED   = 'Confirmed';

    public static boolean bPreventAU = false;
    public static boolean bPreventAI = false;

    public static boolean bPreventBU = false;
    public static boolean bPreventBI = false;
    
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyyy)          Author                      Description
    *           ----  -----------------    -------------------       -----------------------------
    * @version   1.0  23-06-2022             Von Pernicia            [CCN-EVE-2390-DV] Intial Version. This will update date and time depends on the status value.
    ******************************************************************************/ 
    public static void onBeforeInsert(List<Internal_Resource_Session__c> newInternalResourceList, Map<Id, Internal_Resource_Session__c> newInternalResourceMap) {

        Set<String> eventDelConfirmationContactIds = new Set<String>();
        Compass_Setting__c compassSetting = [SELECT Id, Domain_Name_Event_Registration__c FROM Compass_Setting__c WHERE Name = 'Default Settings' LIMIT 1];

        for(Internal_Resource_Session__c newResource : newInternalResourceList) {

            // set domain name
            newResource.Domain_Name__c = compassSetting.Domain_Name_Event_Registration__c;

            // set datetime
            InternalResourceSessionTriggerHelper.updateDateTime(newResource);

            // Added to set to be insert to batch processor
            if (newResource.Resource_Session_Status__c == REGISTERED) {
                eventDelConfirmationContactIds.add(newResource.Resource__c);
            }
        }

        // Added to set to be insert to batch processor
         if (!eventDelConfirmationContactIds.isEmpty()) {
            BatchProcessorUtility.insertBatchRecord(eventDelConfirmationContactIds, 'BatchEventDeliveryConfirmation', 'InternalResourceSessionTriggerHandler', '');
        }
    }

    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyyy)          Author                      Description
    *           ----  -----------------    -------------------       -----------------------------
    * @version   1.0  23-06-2022             Von Pernicia            [CCN-EVE-2390-DV] Intial Version. This will update date and time depends on the status value.
    ******************************************************************************/ 
    public static void onBeforeUpdate(List<Internal_Resource_Session__c> newInternalResourceList, Map<Id, Internal_Resource_Session__c> newInternalResourceMap, 
                                     List<Internal_Resource_Session__c> oldInternalResourceList, Map<Id, Internal_Resource_Session__c> oldInternalResourceMap) {
        
        Set<String> eventDelConfirmationContactIds = new Set<String>();

        for(Internal_Resource_Session__c newResource : newInternalResourceList) {

            if (newResource.Resource_Session_Status__c != oldInternalResourceMap.get(newResource.Id).Resource_Session_Status__c) {

                // set datetime
                InternalResourceSessionTriggerHelper.updateDateTime(newResource);

                // Added to set to be insert to batch processor
                if (newResource.Resource_Session_Status__c == REGISTERED) {
                    eventDelConfirmationContactIds.add(newResource.Resource__c);
                }
            }
        }

        // Added to set to be insert to batch processor
        if (!eventDelConfirmationContactIds.isEmpty()) {
            BatchProcessorUtility.insertBatchRecord(eventDelConfirmationContactIds, 'BatchEventDeliveryConfirmation', 'InternalResourceSessionTriggerHandler', '');
        }
    }

    /******************************************************************************
    * @author       JC Espino
    * @date         20-06-2022

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy)    Author               Description
    *           ----  ---------         --------------------  -----------------------------
    * @version   1.0  20-06-2023        JC Espino             [CCN-EVE-3072-DV] Initial version.
    ******************************************************************************/
    public static void onAfterInsert(List<Internal_Resource_Session__c> newInternalResourceList, Map<Id, Internal_Resource_Session__c> newInternalResourceMap, 
                                     List<Internal_Resource_Session__c> oldInternalResourceList, Map<Id, Internal_Resource_Session__c> oldInternalResourceMap) {

        Set<Id> emailRecepientIds   = new Set<Id>();

        for(Internal_Resource_Session__c newResource : newInternalResourceList) {

            if(newResource.Resource_Session_Status__c == REGISTERED && newResource.Contact__c != null) {

                emailRecepientIds.add(newResource.Id);
            }

            if(!emailRecepientIds.isEmpty()) {
                InternalResourceSessionTriggerHelper.sendCalendarInvites(emailRecepientIds);
            }
        }
    }
    
    /******************************************************************************
    * @author       JC Espino
    * @date         20-06-2022

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy)    Author               Description
    *           ----  ---------         --------------------  -----------------------------
    * @version   1.0  20-06-2023        JC Espino             [CCN-EVE-3072-DV] Initial version.
    ******************************************************************************/
    public static void onAfterUpdate(List<Internal_Resource_Session__c> newInternalResourceList, Map<Id, Internal_Resource_Session__c> newInternalResourceMap, 
                                     List<Internal_Resource_Session__c> oldInternalResourceList, Map<Id, Internal_Resource_Session__c> oldInternalResourceMap) {
                
        Set<Id> emailRecepientIds   = new Set<Id>();

        for(Internal_Resource_Session__c newResource : newInternalResourceList) {
            Internal_Resource_Session__c oldResource = oldInternalResourceMap.get(newResource.Id);

            if(oldResource.Resource_Session_Status__c != newResource.Resource_Session_Status__c && 
               newResource.Contact__c != null) {

                emailRecepientIds.add(newResource.Id);
            }
        }

        if(!emailRecepientIds.isEmpty()) {
            InternalResourceSessionTriggerHelper.sendCalendarInvites(emailRecepientIds);
        }
    }
}