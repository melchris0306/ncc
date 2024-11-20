public with sharing class MaterialsControllerHelper {

    private static WithoutSharingClass withoutShare = new WithoutSharingClass();
    

    public static String getEventHelper(String eventId){
        return JSON.serialize(withoutShare.getEvent(eventId)); 
    }
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  09-21-2022   Rianno Rizarri       [CCN-912] This method check the event material fields.
    * @version   1.1  10-12-2022   JC Espino            [CCN-EVE-2170-DV] Replaced instance of Description__c with Group_Description__c
    ******************************************************************************/
    public static Map<String, Boolean> checkEventMaterialDetailsHelper(String eventId){
        Map<String, Boolean> eventDetails = new Map<String, Boolean>();
        List<Event__c> eventRec = new List<Event__c>();
        eventRec = withoutShare.getEventWithGeneralMaterialsGroup(eventId);
        if(eventRec != null && eventRec.size() > 0 && eventRec[0].General_Material_Groups__r.size() > 0){
            eventDetails.put('hasGMG', true);
        }else{
            eventDetails.put('hasGMG', false);
        }
        eventDetails.put('sessionWithGeneralMaterials', eventRec[0].Sessions_with_General_Materials__c);
        return eventDetails;
    }



    // Retrieve the files that belong to the record Ids
    public static String getMaterialsHelper(String eventId){
        List<MaterialWrapper> materials = new List<MaterialWrapper>();
        //eventId = '7RvETWUOkMc';
        Set<Id> campaignIds = new Set<Id>();
        // Retrieve the event's Salesforce recordId
        Event__c eventrec = new Event__c();

        if(FlsUtils.isAccessible('Event__c', new List<String>{'Name'})){
            eventrec = withoutShare.getEvent(eventId);
        }
        campaignIds.add(eventrec.Id);

        // Retrieve a map of contentDocumentId and Title
        Map<Id, ContentDocumentLink> contentDocumentLinkTitleMap = new Map<Id, ContentDocumentLink>();
        for (ContentDocumentLink cdl : withoutShare.getContentDocumentLinks(campaignIds)){
            contentDocumentLinkTitleMap.put(cdl.ContentDocument.Id, cdl);
        }

        // Retrieive a map of contentDocumentId and DistributionPublicUrl
        Map<ID, String> contentDistributionMap = new Map<Id, String>();
        Map<String,String> acceptedVideoFormats = new Map<String,String>();
        
        // get valid video format for files
        for(Accepted_Video_Format_Settings__mdt videoFormat : withoutShare.getValidVideoFormats()) {
            acceptedVideoFormats.put(videoFormat.MasterLabel.toLowerCase(),videoFormat.Id);
        }

        if (!contentDocumentLinkTitleMap.isEmpty()){
            for (ContentDistribution cd : withoutShare.getContentDistributions(contentDocumentLinkTitleMap.keySet())){
                if (String.isNotBlank(cd.DistributionPublicURL)){
                    if(acceptedVideoFormats.containskey(contentDocumentLinkTitleMap.get(cd.ContentDocumentId).ContentDocument.FileType.toLowerCase())) {
                        contentDistributionMap.put(cd.ContentDocumentId, cd.ContentDownloadURL);
                    } else {
                        contentDistributionMap.put(cd.ContentDocumentId, cd.DistributionPublicURL);
                    }
                }
            }
        }

        // From the 2 maps above, construct a list of material wrappers to return to the component
        for (String key : contentDocumentLinkTitleMap.keySet()){
            if (!String.isBlank(contentDistributionMap.get(key))){
                MaterialWrapper mw = new MaterialWrapper();
                mw.Title = contentDocumentLinkTitleMap.get(key).ContentDocument.Title;
                mw.Description = contentDocumentLinkTitleMap.get(key).ContentDocument.Description;
                mw.DownloadURL = contentDistributionMap.get(key);
                mw.FileType = contentDocumentLinkTitleMap.get(key).ContentDocument.FileType;
                mw.Id = key;
                mw.isVideo = acceptedVideoFormats.containskey(contentDocumentLinkTitleMap.get(key).ContentDocument.FileType.toLowerCase());
                materials.add(mw);
            }
        }
         
        return JSON.serialize(materials); 
    }

    // Retrieve the files that belong to the record Ids
    public static String getMaterialsHelperGrouped(String eventId){
        //List<MaterialWrapper> materials = new List<MaterialWrapper>();
        //eventId = '7RvETWUOkMc';
        Set<Id> campaignIds = new Set<Id>();
        // Retrieve the event's Salesforce recordId
        List<General_Material_Group__c> materialGroup = new List<General_Material_Group__c>();
        materialGroup = withoutShare.getMaterialGrouping(eventId);
        
        for(General_Material_Group__c gmg : materialGroup){
            campaignIds.add(gmg.Id);
        }

        // Retrieve a map of contentDocumentId and Title
        Map<Id, ContentDocumentLink> contentDocumentLinkTitleMap = new Map<Id, ContentDocumentLink>();
        for (ContentDocumentLink cdl : withoutShare.getContentDocumentLinks(campaignIds)){
            contentDocumentLinkTitleMap.put(cdl.ContentDocument.Id, cdl);
        }

        // Retrieive a map of contentDocumentId and DistributionPublicUrl
        Map<ID, String> contentDistributionMap = new Map<Id, String>();
        Map<String,String> acceptedVideoFormats = new Map<String,String>();
        
        // get valid video format for files
        for(Accepted_Video_Format_Settings__mdt videoFormat : withoutShare.getValidVideoFormats()) {
            acceptedVideoFormats.put(videoFormat.MasterLabel.toLowerCase(),videoFormat.Id);
        }

        if (!contentDocumentLinkTitleMap.isEmpty()){
            for (ContentDistribution cd : withoutShare.getContentDistributions(contentDocumentLinkTitleMap.keySet())){
                if (String.isNotBlank(cd.DistributionPublicURL)){
                    if(acceptedVideoFormats.containskey(contentDocumentLinkTitleMap.get(cd.ContentDocumentId).ContentDocument.FileType.toLowerCase())) {
                        contentDistributionMap.put(cd.ContentDocumentId, cd.ContentDownloadURL);
                    } else {
                        contentDistributionMap.put(cd.ContentDocumentId, cd.DistributionPublicURL);
                    }
                }
            }
        }

        Map<Id,List<CCMaterialWrapper.material>> groupMaterialMap = new Map<Id,List<CCMaterialWrapper.material>>();
        // From the 2 maps above, construct a list of material wrappers to return to the component
        for (String key : contentDocumentLinkTitleMap.keySet()){
            if (!String.isBlank(contentDistributionMap.get(key))){

                if(groupMaterialMap.get(contentDocumentLinkTitleMap.get(key).LinkedEntityId) == null){

                    List<CCMaterialWrapper.material> materialList = new List<CCMaterialWrapper.material>();
                    CCMaterialWrapper.material mw = new CCMaterialWrapper.material();
                    mw.Title = contentDocumentLinkTitleMap.get(key).ContentDocument.Title;
                    mw.Description = contentDocumentLinkTitleMap.get(key).ContentDocument.Description;
                    mw.DownloadURL = contentDistributionMap.get(key);
                    mw.FileType = contentDocumentLinkTitleMap.get(key).ContentDocument.FileType;
                    mw.Id = key;
                    mw.isVideo = acceptedVideoFormats.containskey(contentDocumentLinkTitleMap.get(key).ContentDocument.FileType.toLowerCase());
                    materialList.add(mw);
                    groupMaterialMap.put(contentDocumentLinkTitleMap.get(key).LinkedEntityId,materialList);

                }else{
                    
                    List<CCMaterialWrapper.material> materialList = groupMaterialMap.get(contentDocumentLinkTitleMap.get(key).LinkedEntityId);
                    CCMaterialWrapper.material mw = new CCMaterialWrapper.material();
                    mw.Title = contentDocumentLinkTitleMap.get(key).ContentDocument.Title;
                    mw.Description = contentDocumentLinkTitleMap.get(key).ContentDocument.Description;
                    mw.DownloadURL = contentDistributionMap.get(key);
                    mw.FileType = contentDocumentLinkTitleMap.get(key).ContentDocument.FileType;
                    mw.Id = key;
                    mw.isVideo = acceptedVideoFormats.containskey(contentDocumentLinkTitleMap.get(key).ContentDocument.FileType.toLowerCase());
                    materialList.add(mw);
                    groupMaterialMap.put(contentDocumentLinkTitleMap.get(key).LinkedEntityId,materialList);

                }

            }
        }

        List<CCMaterialWrapper> resultList = new List<CCMaterialWrapper>();
        for(General_Material_Group__c gmg : materialGroup){
            CCMaterialWrapper result = new CCMaterialWrapper();
            result.MaterialHeader = gmg.Group_Header__c;
            result.MaterialDescription = gmg.Group_Description__c;
            result.LinkedEntityId = gmg.id;
            result.Name = gmg.Name;
            result.materialList = groupMaterialMap.get(gmg.id);
            resultList.add(result);
        }
        //resultList.sort();
        System.debug('------------- ' + resultList);
         
        return JSON.serialize(resultList); 
    }

    public static Map<Id,List<CCEEventWrapper.MaterialWrapper>> getSessionMaterialsHelper(Set<Id> sessionIds){
        system.debug('-------------- helper sessionIds' + sessionIds);
        // Retrieve a map of contentDocumentId and Title
        Map<Id, ContentDocumentLink> contentDocumentLinkTitleMap = new Map<Id, ContentDocumentLink>();
        for (ContentDocumentLink cdl : withoutShare.getContentDocumentLinks(sessionIds)){
            system.debug('-------------- cdl' + cdl);
            contentDocumentLinkTitleMap.put(cdl.ContentDocument.Id, cdl);
        }
        system.debug('-------------- contentDocumentLinkTitleMaps' + contentDocumentLinkTitleMap);
        // Retrieive a map of contentDocumentId and DistributionPublicUrl
        Map<ID, String> contentDistributionMap = new Map<Id, String>();
        Map<String,String> acceptedVideoFormats = new Map<String,String>();
        
        // get valid video format for files
        for(Accepted_Video_Format_Settings__mdt videoFormat : withoutShare.getValidVideoFormats()) {
            acceptedVideoFormats.put(videoFormat.MasterLabel.toLowerCase(),videoFormat.Id);
        }

        system.debug('-------------- acceptedVideoFormats' + acceptedVideoFormats);

        if (!contentDocumentLinkTitleMap.isEmpty()){
            for (ContentDistribution cd : withoutShare.getContentDistributions(contentDocumentLinkTitleMap.keySet())){
                system.debug('-------------- cd' + cd);

                if (String.isNotBlank(cd.DistributionPublicURL)){
                    if(acceptedVideoFormats.containskey(contentDocumentLinkTitleMap.get(cd.ContentDocumentId).ContentDocument.FileType.toLowerCase())) {
                        contentDistributionMap.put(cd.ContentDocumentId, cd.ContentDownloadURL);
                    } else {
                        contentDistributionMap.put(cd.ContentDocumentId, cd.DistributionPublicURL);
                    }
                }
            }
        }


        Map<Id,List<CCEEventWrapper.MaterialWrapper>> resultMap = new  Map<Id,List<CCEEventWrapper.MaterialWrapper>>();

        // From the 2 maps above, construct a list of material wrappers to return to the component
        for (String key : contentDocumentLinkTitleMap.keySet()){
            system.debug('-------------- key' + key);
            if (!String.isBlank(contentDistributionMap.get(key))){

                if(resultMap.get(contentDocumentLinkTitleMap.get(key).LinkedEntityId) == null){

                    List<CCEEventWrapper.MaterialWrapper> mwList = new  List<CCEEventWrapper.MaterialWrapper>();
                    CCEEventWrapper.MaterialWrapper mw = new CCEEventWrapper.MaterialWrapper();
                    mw.Title = contentDocumentLinkTitleMap.get(key).ContentDocument.Title;
                    mw.Description = contentDocumentLinkTitleMap.get(key).ContentDocument.Description;
                    mw.DownloadURL = contentDistributionMap.get(key);
                    mw.FileType = contentDocumentLinkTitleMap.get(key).ContentDocument.FileType;
                    mw.Id = key;
                    mw.isVideo = acceptedVideoFormats.containskey(contentDocumentLinkTitleMap.get(key).ContentDocument.FileType.toLowerCase());
                    mwList.add(mw);

                    resultMap.put(contentDocumentLinkTitleMap.get(key).LinkedEntityId,mwList);

                }else{

                    List<CCEEventWrapper.MaterialWrapper> mwList = resultMap.get(contentDocumentLinkTitleMap.get(key).LinkedEntityId);
                    CCEEventWrapper.MaterialWrapper mw = new CCEEventWrapper.MaterialWrapper();
                    mw.Title = contentDocumentLinkTitleMap.get(key).ContentDocument.Title;
                    mw.Description = contentDocumentLinkTitleMap.get(key).ContentDocument.Description;
                    mw.DownloadURL = contentDistributionMap.get(key);
                    mw.FileType = contentDocumentLinkTitleMap.get(key).ContentDocument.FileType;
                    mw.Id = key;
                    mw.isVideo = acceptedVideoFormats.containskey(contentDocumentLinkTitleMap.get(key).ContentDocument.FileType.toLowerCase());
                    mwList.add(mw);

                    resultMap.put(contentDocumentLinkTitleMap.get(key).LinkedEntityId,mwList);

                }


            }
        }
         
        return resultMap;


    }





    public class MaterialWrapper{
        public String Title;
        public String Description;
        public String DownloadURL;
        public String FileType;
        public String Id;
        public Boolean isVideo;
    }

    //Needs inner class declared without sharing for guest users to retrieve relevant records
    private without sharing class WithoutSharingClass {
        public Event__c getEvent(String eventId){
            Event__c eventRec = new Event__c();
            try{
            	eventRec = [SELECT Id, Name,Sessions_with_General_Materials__c FROM Event__c WHERE Event_Id__c = :eventId AND IsActive__c = true LIMIT 1];
            }catch(Exception e){
                throw new AuraHandledException('Inactive events are not available for viewing.');
            }
            return eventRec;
        }
        /******************************************************************************    
        * Changes (version)
        *            No.  Date(dd-mm-yyy) Author            Description
        *           ----  ---------   --------------------  -----------------------------
        * @version   1.0  09-21-2022   Rianno Rizarri       [CCN-912] This method gets the event details and its General Materials Group child records.
        ******************************************************************************/
        public List<Event__c> getEventWithGeneralMaterialsGroup(String eventId){
            List<Event__c> eventRec = new List<Event__c>();
            try{
                eventRec = [SELECT Sessions_with_General_Materials__c, Name, (SELECT ID FROM General_Material_Groups__r) FROM Event__c WHERE Event_Id__c = :eventId AND IsActive__c = true LIMIT 1];
            }catch(Exception e){
                throw new AuraHandledException('Inactive events are not available for viewing.');
            }
            return eventRec;
        }

        public List<General_Material_Group__c> getMaterialGrouping(String eventId){
            return [SELECT Id, Group_Header__c,Group_Description__c,Name FROM General_Material_Group__c WHERE Event__r.Event_Id__c = :eventId AND Event__r.IsActive__c = true ORDER BY Name];
        }
        
        public List<ContentDocumentLink> getContentDocumentLinks(Set<Id> campaignIds){
            return [SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.Description, ContentDocument.FileType ,LinkedEntityId
                    FROM ContentDocumentLink 
                    WHERE LinkedEntityId IN :campaignIds 
                    ORDER BY LinkedEntityId, ContentDocument.Title];
        }

        public List<ContentDistribution> getContentDistributions(Set<Id> contentDocumentIdSet){
            return [SELECT ID, DistributionPublicUrl, ContentDocumentId, ContentDownloadURL 
                    FROM ContentDistribution 
                    WHERE ContentDocumentId IN :contentDocumentIdSet];
        }

        public List<Accepted_Video_Format_Settings__mdt> getValidVideoFormats(){
            return [SELECT ID, MasterLabel
                    FROM Accepted_Video_Format_Settings__mdt LIMIT 200];
        }
    }

}