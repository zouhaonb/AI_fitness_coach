// entry/src/main/ets/service/AIService.ts
// DeepSeek AI 服务 — 用于生成个性化训练建议
import { rcp } from '@kit.RemoteCommunicationKit';

class DeepSeekMessage {
  role: string = '';
  content: string = '';
}

class DeepSeekChoice {
  index: number = 0;
  message: DeepSeekMessage = new DeepSeekMessage();
  finishReason: string = '';
}

class DeepSeekResponse {
  choices: Array<DeepSeekChoice> = [];
}

export class AIService {
  // DeepSeek API Key
  // WARNING: 生产环境应通过后端代理，勿将 API Key 硬编码在客户端
  static apiKey: string = 'sk-98d3424a070a48d5b7571ce4ca42ad6e';

  static async generateEncouragement(streakDays: number, weekCount: number, totalMinutes: number, goal: string): Promise<string> {
    let goalText: string = '';
    if (goal === 'lose_fat') {
      goalText = '减脂';
    } else if (goal === 'gain_muscle') {
      goalText = '增肌';
    } else {
      goalText = '保持健康';
    }

    let systemPrompt: string = '你是一个专业的健身教练和激励师。请根据用户的训练数据，用中文生成一句简短的鼓励或训练建议，不超过30字，语气亲切积极。';
    let userPrompt: string = '我的训练数据：连续打卡' + streakDays.toString() + '天，本周训练' + weekCount.toString() + '次，累计运动' + totalMinutes.toString() + '分钟，训练目标是' + goalText + '。请给我一句鼓励。';

    let messages: Array<DeepSeekMessage> = [];
    let sysMsg: DeepSeekMessage = new DeepSeekMessage();
    sysMsg.role = 'system';
    sysMsg.content = systemPrompt;
    messages.push(sysMsg);

    let usrMsg: DeepSeekMessage = new DeepSeekMessage();
    usrMsg.role = 'user';
    usrMsg.content = userPrompt;
    messages.push(usrMsg);

    let result: string = '';
    try {
      result = await AIService.sendRequest(messages);
    } catch (err) {
      console.error('AI request failed: ' + JSON.stringify(err));
      result = '坚持训练，你已经很棒了！';
    }
    if (result === '') {
      result = '坚持训练，你已经很棒了！';
    }
    return result;
  }

  static async generateTrainingAdvice(streakDays: number, weekCount: number, totalMinutes: number, goal: string, frequency: number, categorySummary: string): Promise<string> {
    let goalText: string = '保持健康';
    if (goal === 'lose_fat') {
      goalText = '减脂';
    } else if (goal === 'gain_muscle') {
      goalText = '增肌';
    }

    let systemPrompt: string = '你是一个专业健身教练。根据用户训练数据，从4个维度各给出1条简短建议（每条不超过25字）。严格按格式输出：\n1.[训练量]建议\n2.[部位均衡]建议\n3.[计划优化]建议\n4.[休息建议]';
    let userPrompt: string = '数据：目标' + goalText + '，每周' + frequency.toString() + '天，连续打卡' + streakDays.toString() + '天，本周' + weekCount.toString() + '次，累计' + totalMinutes.toString() + '分钟，部位占比：' + categorySummary;

    let messages: Array<DeepSeekMessage> = [];
    let sysMsg: DeepSeekMessage = new DeepSeekMessage();
    sysMsg.role = 'system';
    sysMsg.content = systemPrompt;
    messages.push(sysMsg);

    let usrMsg: DeepSeekMessage = new DeepSeekMessage();
    usrMsg.role = 'user';
    usrMsg.content = userPrompt;
    messages.push(usrMsg);

    let result: string = '';
    try {
      result = await AIService.sendRequest(messages);
    } catch (err) {
      console.error('AI training advice failed: ' + JSON.stringify(err));
      result = '暂无法获取训练建议，请检查网络后重试';
    }
    return result;
  }

  private static async sendRequest(messages: Array<DeepSeekMessage>): Promise<string> {
    let session: rcp.Session = rcp.createSession({
      requestConfiguration: {
        transfer: {
          timeout: {
            connectMs: 10000,
            transferMs: 30000
          }
        }
      }
    });

    let requestBody: DeepSeekRequest = new DeepSeekRequest();
    requestBody.model = 'deepseek-chat';
    requestBody.messages = messages;
    requestBody.stream = false;

    let headers: rcp.RequestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + AIService.apiKey
    };

    let request: rcp.Request = new rcp.Request('https://api.deepseek.com/v1/chat/completions', 'POST', headers, requestBody);

    try {
      let response: rcp.Response = await session.fetch(request);

      if (response.statusCode === 200) {
        let jsonResult: DeepSeekResponse = response.toJSON() as DeepSeekResponse;
        if (jsonResult.choices.length > 0) {
          return jsonResult.choices[0].message.content;
        }
      }
      return '';
    } finally {
      session.close();
    }
  }
}

class DeepSeekRequest {
  model: string = '';
  messages: Array<DeepSeekMessage> = [];
  stream: boolean = false;
}
