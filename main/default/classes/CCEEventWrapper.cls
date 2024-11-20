public class CCEEventWrapper {
    
    @AuraEnabled
    public String EventExternalId {get; set;}
    @AuraEnabled
    public String HeroUrl {get; set;}
    @AuraEnabled
    public String CampaignLogoUrl {get; set;}
    @AuraEnabled
    public String CompanyLogoUrl {get; set;}
    @AuraEnabled
    public String title {get; set;}

    @AuraEnabled
    public String firstName {get; set;}

    @AuraEnabled
    public String subtitle {get; set;}
    @AuraEnabled
    public Time StartTime {get; set;}
    @AuraEnabled
    public Time EndTime {get; set;}
    @AuraEnabled
    public String Description {get; set;}
    @AuraEnabled
    public String Street {get; set;}
    @AuraEnabled
    public String City {get; set;}
    @AuraEnabled
    public String PostalCode {get; set;}
    @AuraEnabled
    public String State {get; set;}
    @AuraEnabled
    public String Country {get; set;}
    @AuraEnabled
    public String LocationName {get; set;}   
    @AuraEnabled
    public String SurveyId {get; set;}
    @AuraEnabled
    public String contactTag {get; set;}
    @AuraEnabled
    public String contactMessage {get; set;}
    @AuraEnabled
    public List<SessionDetail> SessionList {get; set;}
    @AuraEnabled
    public String StartDateTime {get; set;}
    @AuraEnabled
    public String EndDateTime {get; set;}
    @AuraEnabled
    public String CampaignStatus {get; set;}
    @AuraEnabled
    public String homePageTitle {get; set;}
    @AuraEnabled
    public String sessionPageTitle {get; set;}
    @AuraEnabled
    public String materialsPageTitle {get; set;}
    @AuraEnabled
    public String issueTrackerPageTitle {get; set;}
    @AuraEnabled
    public String parkingPageTitle {get; set;}
    @AuraEnabled
    public String surveyPageTitle {get; set;}
    @AuraEnabled
    public String contactUsPageTitle {get; set;}
    @AuraEnabled
    public String learnMorePageTitle {get; set;}
    @AuraEnabled
    public String eventPages {get; set;}
    @AuraEnabled
    public String eventURL {get; set;}
    @AuraEnabled
    public String eventmaterialstr {get; set;}
    @AuraEnabled
    public Boolean showToLinks {get; set;}
    @AuraEnabled
    public String sessionCalendarURL {get; set;} /*Added for CCN-EVE-2012-DV Aug.17.2022*/
    @AuraEnabled
    public Boolean showSessionCalendarLink {get; set;} /*Added for CCN-EVE-2012-DV Aug.17.2022*/
    
    @AuraEnabled
    public String orgTimeZone {get;set;} /*Added for CCN-1070 Jan.15.2022*/

    @AuraEnabled
    public Boolean showLogin {get; set;}
    
    @AuraEnabled
    public Boolean SessionsWithGeneralMaterial {get; set;}

    public class SessionDetail implements childSessionDetail {
        
        @AuraEnabled
        public Boolean isHeader {get; set;}
       @AuraEnabled
        public Id participantSessionId {get; set;}
        @AuraEnabled
        public Boolean isAttended {get; set;}
        @AuraEnabled
        public String title {get; set;}
        @AuraEnabled
        public String subtitle {get; set;}
        @AuraEnabled
        public String SessionDate {get; set;}
        @AuraEnabled
        public String SessionMonth {get; set;} 
        @AuraEnabled
        public String SessionMonthName {get; set;}  
        @AuraEnabled
        public String SessionYear {get; set;} 
        @AuraEnabled
        public String StartTime {get; set;}
        @AuraEnabled
        public String EndTime {get; set;}
        @AuraEnabled
        public String TimeZone {get; set;}
        @AuraEnabled
    	public String sessionPageTitle {get; set;}
        @AuraEnabled
        public List<SessionDetailrec> SessionDetailList  {get; set;}

    }
  
    public class SessionDetailrec {
        
        @AuraEnabled
        public Boolean isHeader {get; set;}
        @AuraEnabled
        public Id sessionId {get; set;}   
        @AuraEnabled
        public Id participantSessionId {get; set;}
        @AuraEnabled
        public Boolean isAttended {get; set;}
        @AuraEnabled
        public String title {get; set;}
        @AuraEnabled
        public String subtitle {get; set;}
        @AuraEnabled
        public String SessionDate {get; set;}
        @AuraEnabled
        public String SessionMonth {get; set;}  
        @AuraEnabled
        public String StartTime {get; set;}
        @AuraEnabled
        public String EndTime {get; set;}
        @AuraEnabled
        public String TimeZone {get; set;}
        @AuraEnabled
    	public String sessionPageTitle {get; set;}
        @AuraEnabled
        public List<MaterialWrapper> materialList {get; set;}
        @AuraEnabled
        public Boolean isActive {get; set;}
        @AuraEnabled
        public DateTime unformattedStartDate {get; set;}
        @AuraEnabled
        public DateTime unformattedEndDate {get; set;}
        @AuraEnabled
        public Boolean isCatchup {get; set;}
        @AuraEnabled
        public DateTime unformattedCatchupStartDate {get; set;}
        @AuraEnabled
        public DateTime unformattedCatchupEndDate {get; set;}
    }    

    public class MaterialWrapper{
        @AuraEnabled
        public String Title  {get; set;} 
        @AuraEnabled
        public String Description  {get; set;}
        @AuraEnabled
        public String DownloadURL  {get; set;}
        @AuraEnabled
        public String FileType {get; set;}
        @AuraEnabled
        public String Id {get; set;} 
        @AuraEnabled
        public Boolean isVideo  {get; set;}
    }
    
}