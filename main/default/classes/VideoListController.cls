public class VideoListController {
    private static final String FILE_TYPE_MP4 = 'MP4';
    
    @AuraEnabled(cacheable=true)
    public static Response getAllVideos(String recordId, String communityUrl){
        System.debug('VideoListController.getAllVideos recordId '+recordId);
        Response response = new Response();
        List<ContentDocumentLink> contentDocumentLinks = getAllContentDocumentLinks(recordId);
        response.result = createVideoWRapperList(contentDocumentLinks, communityUrl);
        System.debug('VideoListController.getAllVideos response '+response);
        return response;
    }  
    
    @TestVisible
    private static List<ContentDocumentLink> getAllContentDocumentLinks(Id recordId){
        return [SELECT Id, ContentDocumentID, ContentDocument.Title, LinkedEntity.type, LinkedEntityId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :recordId AND ContentDocument.FileType = :FILE_TYPE_MP4];
    }
    
    @TestVisible
    private static List<VideoWrapper> createVideoWRapperList(List<ContentDocumentLink> contentDocumentLinks, String communityUrl){
        List<VideoWrapper> videosWrapper = new List<VideoWrapper>();
        for(ContentDocumentLink contentDocumentLink : contentDocumentLinks ){
            string urlLink;
            if(communityUrl != null && communityUrl != ''){
                urlLink = communityUrl +'/sfc/servlet.shepherd/document/download/'+contentDocumentLink.ContentDocumentID + '?operationContext=S1';
            }else{
                urlLink = URL.getSalesforceBaseUrl().toExternalForm()+'/sfc/servlet.shepherd/document/download/'+contentDocumentLink.ContentDocumentID;
            }
            VideoWrapper video = new VideoWrapper();
            video.name = String.valueOf(contentDocumentLink.ContentDocument.Title);
            video.videoId = contentDocumentLink.ContentDocumentID;
            video.videoUrl = urlLink;
            videosWrapper.add(video);
        }
        return videosWrapper ;                                      
    } 
    
    public class Response{
        @AuraEnabled public object result {set;get;}
    }
    
    public class VideoWrapper{
        @AuraEnabled public Id videoId {set;get;}
        @AuraEnabled public String name {set;get;}
        @AuraEnabled public String videoUrl {set;get;}
    }
}