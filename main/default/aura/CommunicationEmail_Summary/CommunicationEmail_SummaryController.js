({
    doInit : function(cmp, event, helper){
        helper.initializeAttributes(cmp, event, helper);
        helper.initializeRecipients(cmp, event, helper);
    },

    handleRemoveCcItem: function(cmp, event, helper){
        const ccPillItems = 'v.ccPillItems';
        const ccRecipients = 'v.ccRecipients';
        helper.removePillItem(cmp, event, ccPillItems);
        helper.removeRecipient(cmp, event, ccRecipients);
    },

    handleRemoveBccItem: function(cmp, event, helper){
        const bccPillItems = 'v.bccPillItems';
        const bccRecipients = 'v.bccRecipients';
        helper.removePillItem(cmp, event, bccPillItems);
        helper.removeRecipient(cmp, event, bccRecipients);
    }


})