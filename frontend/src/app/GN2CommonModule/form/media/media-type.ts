export enum MediaType {
  AUDIO = 'Audio',
  PAGE_WEB = 'Page web',
  PDF = 'PDF',
  PHOTO = 'Photo',
  VIDEO_FICHIER = 'Vidéo (fichier)',
  VIDEO_DAILYMOTION = 'Vidéo Dailymotion',
  VIDEO_VIMEO = 'Vidéo Vimeo',
  VIDEO_YOUTUBE = 'Vidéo Youtube',
}

export const EMBEDDABLE_VIDEO_MEDIA_TYPE: Array<MediaType> = [
  MediaType.VIDEO_DAILYMOTION,
  MediaType.VIDEO_VIMEO,
  MediaType.VIDEO_YOUTUBE,
];
