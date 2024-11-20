/*******************************************************************************************
* @name: CloneCompassCaptureController
* @author: Rianno Rizarri
* @created: May 9 2023
* @description: The apex controller of Clone Compass Capture Aura component
* 
* Changes (version)
* -------------------------------------------------------------------------------------------
*           No.   Date         Author                Description
*           ----  ---------    --------------------  -----------------------------
* @version  1.0  May 9 2023     Rianno Rizarri       CCC-DCM-63-DV - Clone button for Compass Capture. This also clones custom child records.
*********************************************************************************************/
public without sharing class CloneCompassCaptureController {
    /*******************************************************************************************
    * @name: doClone
    * @author: Rianno Rizarri
    * @created: May 9 2023
    * @description: This method clones the record and its custom child records.
    * 
    * Changes (version)
    * -------------------------------------------------------------------------------------------
    *           No.   Date         Author                Description
    *           ----  ---------    --------------------  -----------------------------
    * @version  1.0  May 9 2023     Rianno Rizarri       CCC-DCM-63-DV - This method clones the record and its custom child records.
    *********************************************************************************************/
    @AuraEnabled
    public static String doClone(String parentId, String objectAPIName) {
        String returnMsg;
        try{
            Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Set <String> fieldMap = schemaMap.get(objectAPIName).getDescribe().fields.getMap().keySet();
            List<String> finalFields = new List<String>() ;
            finalFields.addAll(fieldMap);
            SObjectType objToken = Schema.getGlobalDescribe().get(objectAPIName); 
            DescribeSObjectResult objDef = objToken.getDescribe();
            Map<String,String> so = new Map<String,String>();
            Map<String,String> so1 = new Map<String,String>();
            for (Schema.ChildRelationship cr: objDef.getChildRelationships()) 
            {
                if(cr.getField().getDescribe().isAccessible()&& cr.getField().getDescribe().isCreateable()&&cr.getField().getDescribe().isAccessible() && cr.getRelationshipName()!=null){
                    if(cr.getRelationshipName().contains('__r')){
                        so.put(''+cr.getChildSObject()  , ''+cr.getRelationshipName());
                    }
                }
            } 
            
            List<String> subqueries = prepareSubqueries(so, schemaMap);
            String query =
                'SELECT ' + String.join(finalFields, ',')+
                ','+String.join(subqueries, ',') +
                ' FROM ' +objectAPIName +
                ' WHERE Id = \''+parentId+'\' LIMIT 1';
            Sobject parentObj = Database.query(query);
            Map<String,Object> apiNameObjectMap = parentObj.getPopulatedFieldsAsMap();

            Sobject clonedParentRec = parentObj.clone(false, true, false, false);
            clonedParentRec.put('Capture_Title__c', apiNameObjectMap.get('Capture_Title__c') + ' copy');
            Insert clonedParentRec;

            
            List<sObject> childRecords = new List<sObject>();
            for (Schema.ChildRelationship cr: objDef.getChildRelationships()) 
            {

                if(cr.getRelationshipName() != null && 
                    cr.getRelationshipName().contains('__r') &&
                    apiNameObjectMap.containsKey(cr.getRelationshipName())){
                    for(sObject childRec : (List<sObject>)apiNameObjectMap.get(cr.getRelationshipName())){
                        Sobject clonedRec = childRec.clone(false, true, false, false);
                        clonedRec.put(cr.getField(), clonedParentRec.Id);
                        childRecords.add(clonedRec);
                    }
                }
            } 
            Insert childRecords;
            returnMsg = clonedParentRec.Id;
        }
        catch(Exception ex){
            system.debug('CloneCompassCaptureController Error>>> '+ex.getMessage()+ex.getLineNumber());
            returnMsg = 'Error>>>'+ex.getMessage();
        }
        
    return returnMsg;
    }
    
    /*******************************************************************************************
    * @name: prepareSubqueries
    * @author: Rianno Rizarri
    * @created: May 9 2023
    * @description: This method prepares the dynamic query for the child records
    * 
    * Changes (version)
    * -------------------------------------------------------------------------------------------
    *           No.   Date         Author                Description
    *           ----  ---------    --------------------  -----------------------------
    * @version  1.0  May 9 2023     Rianno Rizarri       CCC-DCM-63-DV - This method prepares the dynamic query for the child records
    *********************************************************************************************/
    private static List<String> prepareSubqueries(Map<String , String> childrelatedListObjects, Map <String, Schema.SObjectType> schemaMap){
        List<String> subqueries = new List<String>();
        for(String childObject : childrelatedListObjects.keySet()){
            List<String> childFields = new List<String>();
            Map <String, Schema.SObjectField> fieldMap = schemaMap.get(childObject).getDescribe().fields.getMap();
            for(Schema.SObjectField sof : fieldMap.values()){
                DescribeFieldResult dfr = sof.getDescribe();
                if(dfr.isCreateable()){
                    childFields.add(dfr.getName());
                }
            }
            if(!childFields.isEmpty()){
                String query = '(SELECT ' + String.join(childFields, ',') + ' FROM ' + childrelatedListObjects.get(childObject) + ')';
                subqueries.add(query);
            }
            
        }
        return subqueries;
    }
}