public class ProjectTriggerHandler extends TriggerHandler {
    static String COMMUNITY_NAME = 'CompassProject';
    static String PATH_URL = '/s/raid?id=';
    
    protected override void beforeInsert(List<sObject> newRecords){
        String output = 'default';
        if (!Test.isRunningTest()){
            Network myNetwork = [SELECT Id, UrlPathPrefix FROM Network WHERE UrlPathPrefix = :COMMUNITY_NAME];
            ConnectApi.Community  myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
            output = myCommunity.siteUrl ;
        }
        for (sObject prj : newRecords){
            String outcome = getArbitraryId();
            prj.put('Page_URL__c', output + PATH_URL + outcome);
            prj.put('Raid_Id__c', outcome);
        }
    }
    
    protected override void beforeupdate(Map<Id, sObject> newRecordsMap, Map<Id, sObject> oldRecordsMap){
        String output = 'default';
        if (!Test.isRunningTest()){
            Network myNetwork = [SELECT Id, UrlPathPrefix FROM Network WHERE UrlPathPrefix = :COMMUNITY_NAME];
            ConnectApi.Community  myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
            output = myCommunity.siteUrl ;
        }
        for (sObject prj : newRecordsMap.values()){
            if(prj.get('Raid_Id__c') == null){
                String outcome = getArbitraryId();
                prj.put('Page_URL__c', output + PATH_URL + outcome);
                prj.put('Raid_Id__c', outcome);
            }
        }
    }
    
    private String getArbitraryId(){
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        
        String token = '';
        while (token.length() <= 10) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            token += chars.substring(idx, idx+1);
        }
        
        return token;
    }
}