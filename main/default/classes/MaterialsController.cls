public with sharing class MaterialsController { 

    @AuraEnabled (cacheable = true)
    public static String getEvent(String eventId){
        String result = MaterialsControllerHelper.getEventHelper(eventId);
        return result;
    }
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  09-21-2022   Rianno Rizarri       [CCN-912] This method check the event material fields.
    ******************************************************************************/
    @AuraEnabled (cacheable = true)
    public static Map<String, Boolean> checkEventMaterialDetails(String eventId){
        return MaterialsControllerHelper.checkEventMaterialDetailsHelper(eventId);
    }
    
    @AuraEnabled (cacheable = true)
    public static String getMaterials(String eventId){
        String result = MaterialsControllerHelper.getMaterialsHelper(eventId);
        return result;
    }

    @AuraEnabled (cacheable = true)
    public static String getMaterialsGrouped(String eventId){
        String result = MaterialsControllerHelper.getMaterialsHelperGrouped(eventId);
        return result;
    }

}