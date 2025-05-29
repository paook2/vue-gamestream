<script setup>
import { modalStore } from '../store/modalStore'
import GameVideoPlayer from './GameVideoPlayer.vue'
</script>

<template>
  <div class="game-modal" v-if="modalStore.state.show">
    <div class="game-modal__backdrop" @click="modalStore.closeModal" />
    <div class="game-modal__content">
      <GameVideoPlayer :video="modalStore.state.game.videosUrls.tablet" />
    </div>
  </div>
</template>

<style scoped>
.game-modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.game-modal__backdrop {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 0;
  cursor: pointer;
}

.game-modal__content {
  position: relative;
  z-index: 1;
  padding: 1rem;
  width: 80%;
  background-color: #fff;
  border-radius: 0.5rem;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);
}
</style>
