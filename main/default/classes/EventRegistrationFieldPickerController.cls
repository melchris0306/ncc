/**
 * @description Controller class for 'EventRegistrationFieldPicker' Aura Component
 * @revision
 *           06/05/2021 - Kyzer Buhay - Initial Creation
 * 			 06/06/2021 - Pamela Kiang
 **/
public with sharing class EventRegistrationFieldPickerController {
    
    /*******************************************************************************
   * @author       Kyzer Buhay
   * @date         06/05/2021
   * @description  Uses Registration_Field_Configuration__mdt to get available fields to display in Registration config
   * @revision     06/05/2021 - Kyzer Buhay - Created
   *               02/01/2023 - Rianno Rizarri - Add the activation of field on the event registration field picker component.
   *******************************************************************************/
    @AuraEnabled
    public static List<RegistrationFields> getAvailableRegistrationFields(String eventRecordId){
        List<RegistrationFields> fieldFormWrapperList = new List<RegistrationFields>();
        
        try{
            Event__c currentEventRecord;
            if (FLSUtils.isAccessible('Event__c', new List<String>{'Registration_Fields_JSON__c'})){
                currentEventRecord = getEventRecord(eventRecordId);
            }
            Map<String, Map <String,Boolean>> recordFieldWrapper = new Map<String, Map <String,Boolean>>();
    
            if(String.isNotBlank(currentEventRecord.Registration_Fields_JSON__c)){
                //Start [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
                //                                            - Update JSON Deserialize data type. From Map<String, Boolean> to Map<String, Map <String,Boolean>>
                Map<String, Map <String,Boolean>> regFieldConfig = (Map<String, Map <String,Boolean>>) JSON.deserialize(currentEventRecord.Registration_Fields_JSON__c, Map<String, Map <String,Boolean>>.class);
                //End [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
                for(String key : regFieldConfig.keySet()){
                    recordFieldWrapper.put(key, regFieldConfig.get(key));
                }
            }
            
            for(Registration_Field_Configuration__mdt fieldMdt : getEventFieldRegistrationMdt()){
                final String KEY = fieldMdt.DeveloperName + '-' + fieldMdt.Object_API_Name__c + '|' + fieldMdt.Field_API_Name__c;
    
                RegistrationFields fieldFormWrapper = new RegistrationFields(
                    KEY,  fieldMdt.Label,
                    //Start [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
                    //                                            - Add active parameter
                    recordFieldWrapper.containsKey(KEY) && recordFieldWrapper.get(KEY).containsKey('active') ? recordFieldWrapper.get(KEY).get('active') : fieldMdt.Is_Active__c,
                    //End [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
                    recordFieldWrapper.containsKey(KEY) && recordFieldWrapper.get(KEY).containsKey('required') ? recordFieldWrapper.get(KEY).get('required') : fieldMdt.Is_Required__c
                );
                
                fieldFormWrapperList.add(fieldFormWrapper);
            }
        }catch (Exception e) {
            System.debug('@@@@@ error in: ' + e.getLineNumber() + ' - ' + e.getMessage() + ' - ' + e.getCause());
            throw new AuraHandledException(e.getLineNumber() + ' - ' + e.getMessage() + ' - ' + e.getCause());
        }
        

        return fieldFormWrapperList;
    }
    
    /*******************************************************************************
   * @author       Kyzer Buhay
   * @date         06/05/2021
   * @description  Save stringified JSON format from Aura to Registration_Fields_JSON__c field
   * @revision     06/05/2021 - Kyzer Buhay - Created
   *******************************************************************************/
    @AuraEnabled
    public static Boolean saveRegistrationFormFields(String eventRecordId, String updatedRegistrationFieldJSON ){
        Boolean hasErrors = false;
        Event__c eventRec = new Event__c (Id = eventRecordId, Registration_Fields_JSON__c = updatedRegistrationFieldJSON);
        try{
            if(FLSUtils.isUpdateable(eventRec, new List<String>{'Registration_Fields_JSON__c'})){
                update eventRec;
            }
        }catch(Exception e){
            hasErrors = true;
            System.debug('@@@@@ error in: ' + e.getLineNumber() + ' - ' + e.getMessage() + ' - ' + e.getCause());
        }
        
        return hasErrors;
    }
    
    public static Event__c getEventRecord(String eventId){
        return [SELECT Id, Registration_Fields_JSON__c FROM Event__c WHERE Id= : eventId];
    }

    
    public static List<Registration_Field_Configuration__mdt> getEventFieldRegistrationMdt(){
        return [SELECT Label, Field_API_Name__c, Field_Type__c, Is_Required__c, 
                Object_API_Name__c, Order__c, Is_Active__c, DeveloperName
                    FROM Registration_Field_Configuration__mdt
                    ORDER BY Order__c 
                    LIMIT 5000];
    }
}