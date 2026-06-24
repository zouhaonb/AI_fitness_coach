// entry/src/main/ets/service/TTSService.ts
import { textToSpeech } from '@kit.CoreSpeechKit';

class TTSService {
  private engine: textToSpeech.TextToSpeechEngine | null = null;
  private initialized: boolean = false;
  private requestId: number = 0;

  async init(): Promise<void> {
    if (this.initialized) {
      return;
    }
    try {
      let initParams: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        person: 0,
        online: 1
      };
      this.engine = await textToSpeech.createEngine(initParams);
      this.initialized = true;
      console.info('TTSService initialized');
    } catch (err) {
      console.error('TTSService init failed: ' + JSON.stringify(err));
    }
  }

  async speak(text: string): Promise<void> {
    if (!this.initialized || this.engine === null) {
      await this.init();
    }
    if (this.engine === null) {
      return;
    }
    try {
      this.requestId++;
      let speakParams: textToSpeech.SpeakParams = {
        requestId: 'tts_' + this.requestId.toString()
      };
      this.engine.speak(text, speakParams);
    } catch (err) {
      console.error('TTSService speak failed: ' + JSON.stringify(err));
    }
  }

  shutdown(): void {
    if (this.engine !== null) {
      try {
        this.engine.shutdown();
      } catch (err) {
        console.error('TTSService shutdown failed');
      }
      this.engine = null;
      this.initialized = false;
    }
  }
}

export const ttsService: TTSService = new TTSService();
