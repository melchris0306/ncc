public with sharing class FlsUtils {

    public static String prefix {
        get {
            if (prefix == null) {
                String[] parts = String.valueOf(FlsUtils.class).split('\\.', 2);
                prefix = parts.size() == 2 ? parts[0] + '__' : '';
            }

            return prefix;
        }
        private set;
    }

    public static Boolean isAccessible( String sobjectName, List<String> fields ) {
        String[] sObjectNames = new String[] { applyPrefixToObject(sobjectName) };
        Schema.DescribeSObjectResult[] dResult = Schema.describeSObjects(sObjectNames);

        if ( dResult[0].isAccessible() ) {
            Map<String,Schema.SObjectField> fieldMap = dResult[0].fields.getMap();
            for ( String fieldToCheck : fields ) {
                final String FIELD_NAME = applyPrefixToField(dResult[0], fieldToCheck);

                if (!fieldMap.get(FIELD_NAME).getDescribe().isAccessible()) {
                    return false;
                }
            }
            
            return true;
        } else {
            return false;
        }
    }


    public static Boolean isCreateable( sObject sObj, List<String> fields ) {
        Schema.DescribeSObjectResult describeResult = sObj.getSObjectType().getDescribe();

        if (describeResult.isCreateable() || describeResult.getName()=='Task') {
            Map<String,Schema.SObjectField> fieldMap = describeResult.fields.getMap();

            for ( String fieldToCheck : fields ) {
                final String FIELD_NAME = applyPrefixToField(describeResult, fieldToCheck);

                if (!fieldMap.get(FIELD_NAME).getDescribe().isCreateable()) {
                    return false;
                }
            }

            return true;
        } else {

            return false;   
        }
    }

    public static Boolean isUpdateable( sObject sObj, List<String> fields) {

        Schema.DescribeSObjectResult describeResult = sObj.getSObjectType().getDescribe();

        if (describeResult.isUpdateable()) {
            Map<String,Schema.SObjectField> fieldMap = describeResult.fields.getMap();

            for (String fieldToCheck : fields) {
                final String FIELD_NAME = applyPrefixToField(describeResult, fieldToCheck);

                if (!fieldMap.get(FIELD_NAME).getDescribe().isUpdateable()) {
                    return false;
                }
            }

            return true;
        } else {
            return false;
        }
    }


    public static Boolean isDeletable( sObject sObj ){
        return sObj.getSObjectType().getDescribe().isDeletable();
    }

    public static String applyPrefixToObject( String sObjectName ) {
        Set<string> standardObjectSet = new Set<string>();

        for ( Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()){
            String name = objTyp.getDescribe().getName();

            // Exclude all the unwanted Sobjects e.g. History, Share etc..
            if( !name.containsIgnoreCase('history') 
                && !name.containsIgnoreCase('tag')
                && !name.containsIgnoreCase('share') 
                && !name.containsIgnoreCase('feed')
            ) {      
                standardObjectSet.add(name);
            }
        }

        return (standardObjectSet.contains(sObjectName)) ? sObjectName : prefix + sObjectName;
    }

    public static String applyPrefixToField( DescribeSObjectResult sObjectDescribe, String fieldName ) {
        Map<String,Schema.SObjectField> fieldMap = sObjectDescribe.fields.getMap();
        Set<String> standardFieldSet = new Set<String> ();
        
        if (fieldMap.containsKey(fieldName)) {
            DescribeFieldResult dField = fieldMap.get(fieldName).getDescribe();

            if (dField.getName().equals( dField.getLocalName())) {
                standardFieldSet.add(dField.getName());
            }
        }

        return (standardFieldSet.contains(fieldName)) ? fieldName : prefix + fieldName;
    }
}