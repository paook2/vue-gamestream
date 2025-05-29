<script setup>
import { ref, defineProps } from 'vue'
import IconChevronLeft from '../Icons/IconChevronLeft.vue'
import IconChevronRight from '../Icons/IconChevronRight.vue'

const icons = {
  'left': IconChevronLeft,
  'right': IconChevronRight
}

const props = defineProps({
  images: {
    type: Array,
    required: true,
  },
})

const currentIndex = ref(0)

function nextImage() {
  currentIndex.value = (currentIndex.value + 1) % props.images.length
}

function prevImage() {
  currentIndex.value = (currentIndex.value - 1 + props.images.length) % props.images.length
}
</script>

<template>
  <div class="game-gallery">
    <div class="game-gallery__controls">
      <button class="game-gallery__button game-gallery__button--left" @click="prevImage">
        <component :is="icons['left']"></component>
      </button>
      <button class="game-gallery__button game-gallery__button--right" @click="nextImage">
        <component :is="icons['right']"></component>
      </button>
    </div>

    <div class="game-gallery__image-container">
      <img v-if="images.length" :src="images[currentIndex]" :alt="`Imagen ${currentIndex + 1}`" />
      <p v-else>No hay imágenes disponibles</p>
    </div>
  </div>
</template>

<style scoped>
.game-gallery {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin: 0 auto;
  position: relative;
}

.game-gallery__controls {
  display: flex;
  justify-content: space-between;
  width: 100%;
  margin-bottom: 1rem;
}

.game-gallery__image-container {
  width: 100%;
  border-radius: 0.5rem;
  overflow: hidden;
  background-color: #fff;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
  text-align: center;
}

.game-gallery__image-container img {
  width: 100%;
  height: auto;
  display: block;
  object-fit: cover;
}

.game-gallery__image-container p {
  margin: 1rem;
}

.game-gallery__button {
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--color-background-primary);
  border: none;
  cursor: pointer;
  height: 2.25rem;
  width: 2.25rem;
  border-radius: 50%;
  position: absolute;
  color: var(--color-primary);
  top: calc(50% - 1rem);
  opacity: 0.5;
  transition: opacity 0.2s;
}

.game-gallery__button:hover {
  opacity: 1;
}

.game-gallery__button--left {
  left: 8px;
}

.game-gallery__button--right {
  right: 8px;
}
</style>
