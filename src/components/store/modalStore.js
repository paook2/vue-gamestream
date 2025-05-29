import {reactive} from "vue";

export const modalStore = reactive({
	state: {
		show: false,
		game: {}
	},
	openModal(game = {}){
		this.state.show = true

		if(Object.keys(game).length){
			this.state.game = game
		}
	},
	closeModal(){
		this.state.show = false
		this.state.game = {}
	}
})