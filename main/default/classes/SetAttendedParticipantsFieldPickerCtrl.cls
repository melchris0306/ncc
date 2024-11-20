/****************************************************************************************
* Class : SetAttendedParticipantsFieldPickerCtrl
* Created By : RLugpatan
----------------------------------------------------------------------------------------
* Description : Controller for AccountBalance web component.
----------------------------------------------------------------------------------------
* Test Class : SetAttendedParticipantsFieldPickerCtrl_Test
----------------------------------------------------------------------------------------
* Version History:
* VERSION     DEVELOPER NAME       DATE           DESCRIPTION
  1.0         RLugpatan            30.11.2021     [CCN975] Initial Development
***************************************************************************************/
public with sharing class SetAttendedParticipantsFieldPickerCtrl {

   /**
    * @description  Uses Attended_Participant_Field_Configuration__mdt to get available fields to display in Set Attended Participant modal
    * @author       RLugpatan | 30/11/2021 | [CCN975]
    * @param eventRecordId 
    **/
    @AuraEnabled
    public static List<AttendedParticipantFields> getAttendedParticipantFields(String eventRecordId){
        List<AttendedParticipantFields> fieldFormWrapperList = new List<AttendedParticipantFields>();
        
        try{
            Event__c currentEventRecord;
            if (FLSUtils.isAccessible('Event__c', new List<String>{'Attended_Participant_Fields_JSON__c'})){
                currentEventRecord = getEventRecord(eventRecordId);
            }
            Map<String, Boolean> recordFieldWrapper = new Map<String, Boolean>();
    
            if(String.isNotBlank(currentEventRecord.Attended_Participant_Fields_JSON__c)){
                Map<String, Boolean> regFieldConfig = (Map<String, Boolean>) JSON.deserialize(currentEventRecord.Attended_Participant_Fields_JSON__c, 
                                                                Map<String, Boolean>.class);
                
                for(String key : regFieldConfig.keySet()){
                    recordFieldWrapper.put(key, regFieldConfig.get(key));
                }
            }
            
            for(Attended_Participant_Field_Configuration__mdt fieldMdt : getAttendedParticipantMdt()){
                final String KEY = fieldMdt.DeveloperName + '-' + fieldMdt.Object_API_Name__c + '|' + fieldMdt.Field_API_Name__c;
    
                AttendedParticipantFields fieldFormWrapper = new AttendedParticipantFields(
                    KEY,  fieldMdt.Label,
                    recordFieldWrapper.containsKey(KEY) ? true : fieldMdt.Is_Active__c,
                    recordFieldWrapper.containsKey(KEY) ? recordFieldWrapper.get(KEY) : fieldMdt.Is_Required__c
                );
                
                fieldFormWrapperList.add(fieldFormWrapper);
            }
        }catch (Exception e) {
            System.debug('@@@@@ error in: ' + e.getLineNumber() + ' - ' + e.getMessage() + ' - ' + e.getCause());
        }
        

        return fieldFormWrapperList;
    }
    
    @AuraEnabled
    public static Boolean saveAttendedParticipantFields(String eventRecordId, String updatedAttendedParicipantFieldJSON ){
        Boolean hasErrors = false;
        Event__c eventRec = new Event__c (Id = eventRecordId, Attended_Participant_Fields_JSON__c = updatedAttendedParicipantFieldJSON);
        try{
            if(FLSUtils.isUpdateable(eventRec, new List<String>{'Attended_Participant_Fields_JSON__c'})){
                update eventRec;
            }
        }catch(Exception e){
            hasErrors = true;
            System.debug('@@@@@ error in: ' + e.getLineNumber() + ' - ' + e.getMessage() + ' - ' + e.getCause());
        }
        
        return hasErrors;
    }
    
    public static Event__c getEventRecord(String eventId){
        return [SELECT Id, Attended_Participant_Fields_JSON__c FROM Event__c WHERE Id= : eventId];
    }

    
    public static List<Attended_Participant_Field_Configuration__mdt> getAttendedParticipantMdt(){
        return [SELECT Label, Field_API_Name__c, Field_Type__c, Is_Required__c, 
                 Object_API_Name__c, Order__c, Is_Active__c, DeveloperName
                    FROM Attended_Participant_Field_Configuration__mdt
                    ORDER BY Order__c 
                    LIMIT 5000];
    }
}