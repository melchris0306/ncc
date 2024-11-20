public class CCESpeakerWrapper {

    @AuraEnabled
    public String FirstName {get; set;}
    @AuraEnabled
    public String lastName {get; set;}
    @AuraEnabled
    public String Description {get; set;}
    @AuraEnabled
    public String ProfilePicUrl {get; set;}
    @AuraEnabled
    public String Title {get; set;}
    @AuraEnabled
    public Boolean isHideProfilePic {get; set;}
}