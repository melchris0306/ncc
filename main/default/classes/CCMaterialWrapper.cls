public class CCMaterialWrapper {
    @AuraEnabled
    public String Name;   
    @AuraEnabled
    public String MaterialHeader;
    @AuraEnabled
    public String MaterialDescription;
    @AuraEnabled
    public String LinkedEntityId;   
    @AuraEnabled
    public List<material> materialList;    


    public class material {
        @AuraEnabled
        public String LinkedEntityId;
        @AuraEnabled
        public String Title;
        @AuraEnabled
        public String Description;
        @AuraEnabled
        public String DownloadURL;
        @AuraEnabled
        public String FileType;
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public Boolean isVideo;  
    }
    
}