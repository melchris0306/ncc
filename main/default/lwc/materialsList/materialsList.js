import { LightningElement} from 'lwc';
import getMaterials from '@salesforce/apex/MaterialsController.getMaterials';
import getMaterialsGrouped from '@salesforce/apex/MaterialsController.getMaterialsGrouped';
//Start CCN-912 RiannoRizarri Sept212022
import getEventDetail from '@salesforce/apex/MaterialsController.checkEventMaterialDetails';
//End CCN-912 RiannoRizarri Sept212022


// Updated [CCN863,CCN862,CCN1074] JaysonLabnao Dec172021
export default class MaterialsList extends LightningElement {
	// Updated [CCN863,CCN862,CCN1074] JaysonLabnao Dec172021
	showGrouped = false;
	materials;
	materialsGrouped;
	eventId;
	hasGMG;

	connectedCallback(){
		const url = new URL(window.location.href);
		this.eventId = url.searchParams.get("id");
		this.handleGetMaterials();
		this.handleGetMaterialsGrouped();
		this.handleEventDetail();

	}

	// Updated [CCN863,CCN862,CCN1074] JaysonLabnao Dec172021
	renderedCallback(){
		let divElem = this.template.querySelector('.group-container');
		if(divElem) divElem.classList.toggle('group-container-has-dropdown');
	}

	// Updated [CCN863,CCN862,CCN1074] JaysonLabnao Dec172021
	handleEventDetail(){
		getEventDetail({ eventId : this.eventId })
			.then(result =>{
				//Start CCN-912 RiannoRizarri Sept212022
				this.showGrouped = result.sessionWithGeneralMaterials;
				this.hasGMG = result.hasGMG;
				//End CCN-912 RiannoRizarri Sept212022
			})
			.catch(error =>{
				console.log('ERROR handleEventDetail ' + error.message);
			})
	}	

	// Updated [CCN863,CCN862,CCN1074] JaysonLabnao Dec172021
	handleGetMaterials(){
		getMaterials({ eventId : this.eventId })
			.then(result =>{
				this.materials = JSON.parse(result);
			})
			.catch(error =>{
				console.log('ERROR handleGetMaterials ' + error.message);
			})
	}

	// Updated [CCN863,CCN862,CCN1074] JaysonLabnao Dec172021
	handleGetMaterialsGrouped(){
		console.log('result -- ');
		getMaterialsGrouped({ eventId : this.eventId })
			.then(result =>{
				console.log('result -- ' + result);
				this.materialsGrouped = JSON.parse(result);
			})
			.catch(error =>{
				console.log('ERROR handleGetMaterialsGrouped ' + error.message);
			})
	}

	handledownloadall(){
		console.log('materials -- ' + this.materials);
		for(let i=0; i<this.materials.length; i++){
			console.log(this.materials[i].Title);
			window.open(this.materials[i].DownloadURL, '_blank');
		}			
	}

	toggleMaterial(event){
		var groupName = event.target.title;

		this.template.querySelector('div[name="'+groupName+'"]').classList.toggle('slds-hide');
		if(event.target.iconName === "utility:chevrondown"){
			event.target.iconName="utility:chevronup";
		}else{
			event.target.iconName="utility:chevrondown";
		}
	}
}