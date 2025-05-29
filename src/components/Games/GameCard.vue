<script setup>
import GameGallery from './GameGallery.vue'
import GameTag from './GameTag.vue'
import IconPlayCircle from '../Icons/IconPlayCircle.vue'
import { modalStore } from '../store/modalStore'

defineProps({
  game: {
    type: Object,
    default: () => ({
      title: 'Game title',
      description: 'Game description',
      galleryImages: [],
      tags: [],
      publicationYear: 0,
    }),
  },
})
</script>

<template>
  <article class="game-card">
    <GameGallery :images="game.galleryImages" />
    <div class="game-card__info">
      <h3 class="game-card__title">
        {{ game.title }} | <span>{{ game.publicationYear }}</span>
      </h3>
      <div class="game-card__tags">
        <GameTag v-for="tag in game.tags" :key="tag" :tag="tag" />
        <button @click.prevent="()=>{
            modalStore.openModal(game)
          }" class="game-card__video-icon">
          <IconPlayCircle />
        </button>
      </div>
      <p class="game-card__description">{{ game.description }}</p>
    </div>
  </article>
</template>

<style scoped>
.game-card {
  width: calc(100% - 1rem);
  border: 1px solid #ddd;
  border-radius: 0.5rem;
  padding: 1rem;
  background-color: #fff;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
}

.game-card:hover {
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);
}

.game-card__title {
  margin-top: 0.5rem;
  margin-bottom: 0.5rem;
  font-size: 1.5rem;
}

.game-card__title span {
  font-size: 1rem;
  color: #666;
}

.game-card__tags {
  width: 100%;
  display: flex;
  flex-flow: row wrap;
  gap: 0.5rem;
}

.game-card__video-icon {
  margin-left: auto;
  width: 2rem;
  height: 2rem;
  color: var(--color-background-primary);
  background: none;
  border: none;
  padding: 0;
  cursor: pointer;
}

.game-card__video-icon svg {
  width: 32px;
  height: 32px;
}
</style>
