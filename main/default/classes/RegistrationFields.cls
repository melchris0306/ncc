/**
 * @description Wrapper class of Event Registration Field
 * @revision
 *           06/05/2021 - Kyzer Buhay - Initial Creation
 * 			 06/06/2021 - Pamela Kiang
 *           02/01/2023 - Rianno Rizarri - new constructor with active parameter
 **/
public class RegistrationFields {
	@AuraEnabled public String key {get; set;}
    @AuraEnabled public String label {get; set;}
    @AuraEnabled public Boolean active {get; set;}
    @AuraEnabled public Boolean required {get; set;}
    @AuraEnabled public String objectName {get; set;}
    @AuraEnabled public String fieldName {get; set;}
    @AuraEnabled public String messageWhenRequired {get;set;}
    @AuraEnabled public String fieldType {get; set;}
    @AuraEnabled public String inputValue {get; set;}
    @AuraEnabled public List<PicklistOptions> picklistOptions {get;set;}
    
    public RegistrationFields(String key, String label, Boolean active, Boolean required){
        this.key = key;
        this.label = label;
        this.active = active;
        this.required = required;
    }
    
    //Start [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
    //                                            - Created new constructor with added active parameter
    public RegistrationFields(String key, String label, Boolean required, Boolean active, String objectName, String fieldName, 
        String fieldType, String messageWhenRequired){
        this.key = key;
        this.label = label;
        this.required = required;
        //[CCN-2530] RIANNO RIZARRI Feb01.2023 - Add the activation of field on the event registration field picker component.
        this.active = active;
        //[CCN-2530] RIANNO RIZARRI Feb01.2023 - Add the activation of field on the event registration field picker component.
        this.objectName = objectName;
        this.fieldName = fieldName;
        this.fieldType = fieldType;
        this.messageWhenRequired = messageWhenRequired;
        this.inputValue = '';
        this.picklistOptions = new List<PicklistOptions>();
    }
    //End [CCN-2530] RIANNO RIZARRI Feb01.2023 - Add the activation of field on the event registration field picker component.

    public class PicklistOptions {
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String value {get;set;}

        public PicklistOptions(String value, String label){
            this.value = value;
            this.label = label;
        }
    }
}