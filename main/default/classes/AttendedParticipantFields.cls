/**
 * @description Wrapper class of Attended_Participant_Field_Configuration__mdt 
 **/
public class AttendedParticipantFields {
	@AuraEnabled public String key {get; set;}
    @AuraEnabled public String label {get; set;}
    @AuraEnabled public Boolean active {get; set;}
    @AuraEnabled public Boolean required {get; set;}

    
    public AttendedParticipantFields(String key, String label, Boolean active, Boolean required){
        this.key = key;
        this.label = label;
        this.active = active;
        this.required = required;
    }
    
}