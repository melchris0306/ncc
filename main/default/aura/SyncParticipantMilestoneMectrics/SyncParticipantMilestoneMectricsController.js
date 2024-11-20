/***********
 * 03/31/2021 MHM Created
 * Description: copying framework from SyncMilestoneProgress components
 */

({
  doInit: function (cmp) {
    cmp.set("v.showSpinner", true);
    console.log("------ Start");
    var action = cmp.get("c.updateParticipantMilestoneMetrics");
    console.log(' @@@@@ cmp.get(v.recordId)' + cmp.get("v.recordId"));
    action.setParams({
      jIds: cmp.get("v.recordId")
    });

    action.setCallback(this, function (response) {
      var ret = response.getReturnValue();
      var state = response.getState();
      console.log("------ response value: " + ret);
      console.log("------ response state: " + state);

      if (state === "SUCCESS") {
        cmp.set("v.showResult", true);
        if (ret == 'running') {
          cmp.set("v.isSuccess", false); 
          
        } else {
          cmp.set("v.isSuccess", true  ); 
        }
        
        cmp.set("v.showSpinner", false);
        //$A.get("e.force:closeQuickAction").fire();
        $A.get("e.force:refreshView").fire();

     
      }
    });
    $A.enqueueAction(action);
  },

  handleOk: function (cmp) {
    $A.get("e.force:closeQuickAction").fire();
  }
  
});