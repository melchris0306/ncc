public virtual without sharing class FlowCallout {

	static final string SOQLTEMPLATE = 'SELECT ID, {0} FROM {1}{2}';
	static final String ID_KEY = 'Id';
	static final String PAYLOAD_ID = 'salesforceId';
	static final String PAYLOAD_OBJECT_TYPE = 'sobjectType';
	static final String PAYLOAD_FIELD_CONTAINER = 'fields';
	// @author: [CCN-858] Updated by dinoBrinas
	// @description: This is used to avoid the recursive on the apex trigger.
	// @date: oct082021
	public static boolean bPreventAI = false;

	@InvocableMethod(label='Call Sentiment Service' description='Apex Callout for calling a webservice' category='Callout')
	public static void doCallout(List<sObject> records){
		// dynamically get object type
		List<Object> raw = (List<Object>) JSON.deserializeUntyped(JSON.serialize(records));
		// get first instance of the list to extract type
		Map<String, Object> rawInstance = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(raw[0]));
		// get attributes from the object;
		Map<String, Object> rawAttributes = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(rawInstance.get('attributes')));
		// type indicates the sObjectType
		String objectType = (String) rawAttributes.get('type');

		Flow_Callout_Config__mdt config = [
			SELECT Callout_Endpoint__c,
			Fields__c, 
			Filter_Object__r.QualifiedApiName,
			Filter_Object_Condition__c,
			Filter_Object_Field__r.QualifiedApiName,
			Object_Field_Qualifier__r.QualifiedApiName
			FROM Flow_Callout_Config__mdt 
			WHERE Object_Type__r.QualifiedApiName = :objectType 
			LIMIT 1
		];

		// Ingest Field qualifier (optional);
		List<sObject> qualifiers = new List<sObject>();
		//Qualifiers can only have 2 behaviors
		// 1) with field qualifier & condition
		// 2) both are blank
		String qualifierFilter = applyFilterAndQualifier(config, records, qualifiers);

		String query = String.format(SOQLTEMPLATE, new List<String>{
			config.Filter_Object_Field__r.QualifiedApiName,
			config.Filter_Object__r.QualifiedAPIName,
			qualifierFilter
		});

		Map<Id, sObject> filterField = new Map<Id, Sobject>(Database.query(query));

		List<String> fieldsToGet = config.Fields__c.split(',');
		
		List<Object> payload = new List<Object>();

		for (sObject so : records){
			if (!filterField.containsKey((Id) so.get(config.Object_Field_Qualifier__r.QualifiedApiName))) { continue; }
			Map<String, Object> params = new Map<String, Object>{
				PAYLOAD_ID => so.Id,
				PAYLOAD_OBJECT_TYPE => objectType
			};
			List<Object> fields = new List<Object>();
			for (String field : fieldsToGet){
				String f = field.trim();
				fields.add(new Map<String, Object>{
					f => so.get(f)
				});
			}
			params.put(PAYLOAD_FIELD_CONTAINER, fields);
			payload.add(params);
		}
		fireAndForget(JSON.serialize(payload), config.Callout_Endpoint__c);
	}

	public abstract class ApexCallout{
		protected String payload;
		protected String endpoint;
		public ApexCallout(String payload, String endpoint){
			this.payload = payload;
			this.endpoint = endpoint;
		}
		public abstract void callout();
	}

	@testVisible
	private class FireAndForget extends FlowCallout.ApexCallout{
		public FireAndForget(String payload, String endpoint){
			super(payload, endpoint);
		}
		public override void callout(){
			HTTPRequest req = new HTTPRequest();
			req.setEndpoint(this.endpoint);
			req.setBody(this.payload);
			req.setHeader('Content-Type', 'application/json');
			req.setMethod('POST');
			HTTPResponse res = new Http().send(req);	
		}
	}

	@future(callout=true)
	private static void fireAndForget(string payload, String endpoint){
		FlowCallout.ApexCallout action = new FlowCallout.FireAndForget(payload, endpoint);
		action.callout();
	}

	@testVisible
	private static String patternMatch(String filter){
		return ' WHERE ' + filter.replace('{',':').replace('}', '');
	}

	@testVisible
	private interface Expression{
		List<sObject> apply();
	}

	public virtual class FilterExpression implements Expression{
		protected List<sObject> toApply;
		protected String fieldName;
		protected String objectType;
		public FilterExpression(List<sObject> records, String fieldName, String objectType){
			this.toApply = records;
			this.fieldname = fieldName;
			this.objectType = objectType;
		}

		public List<sObject> apply(){
			List<sObject> result = new List<sObject>();
			for (sObject record : this.toApply){
				sObject so = Schema.getGlobalDescribe().get(this.objectType).newSobject();
				so.put(ID_KEY, record.get(this.fieldName));
				result.add(so);
			}
			return result;
		}
	}

	@testVisible
	private static String applyFilterAndQualifier(final Flow_Callout_Config__mdt config, final List<sObject> records, List<sObject> qualifiers){
		if (config.Object_Field_Qualifier__r?.QualifiedAPIName != null && config.Filter_Object_Condition__c != null){
			FlowCallout.Expression expr = new FlowCallout.FilterExpression(
				records, 
				config.Object_Field_Qualifier__r.QualifiedApiName,
				config.Filter_Object__r.QualifiedAPIName
			);
			qualifiers.addAll(expr.apply());
			return FlowCallout.patternMatch(config.Filter_Object_Condition__c);
		}
		return '';
	}
}