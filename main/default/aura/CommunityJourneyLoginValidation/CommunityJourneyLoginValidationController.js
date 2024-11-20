({
  doInit: function (component, event, helper) {
    helper.getURLParameters(component);
    helper.checkObjectHelper(component);
  },

  handleSubmit: function (component, event, helper) {
    helper.validateEmailHelper(component);
  }
});