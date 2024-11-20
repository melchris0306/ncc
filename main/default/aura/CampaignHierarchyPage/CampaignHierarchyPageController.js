({
    doInit: function(component, event, helper) {
        
        //Check RecordId Type
        var recordId = component.get("v.recordId");
        helper.getCampaigns(component, recordId);
        
        var columns = [
            {
                type: 'url',
                fieldName: 'CampaignName',
                label: 'Name',
                typeAttributes: {
                    label: { fieldName: 'Name' }
                }
            },
            {
                type: 'date',
                fieldName: 'Start_Date_Time__c',
                label: 'Start Date'
            },
            {
                type: 'date',
                fieldName: 'End_Date_Time__c',
                label: 'End Date'
            },
            {
                type: 'test',
                fieldName: 'Time_Zone__c',
                label: 'Time Zone'
            },
            {
                type: 'text',
                fieldName: 'RecordType',
                label: 'Record Type'
            },
        ];

        component.set('v.gridColumns', columns);
    }
})