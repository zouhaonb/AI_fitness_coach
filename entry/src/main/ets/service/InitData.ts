// entry/src/main/ets/service/InitData.ts
import { relationalStore } from '@kit.ArkData';

export async function initExerciseData(store: relationalStore.RdbStore): Promise<void> {
  let countSql: string = 'SELECT COUNT(*) FROM exercise';
  let resultSet: relationalStore.ResultSet = await store.querySql(countSql);
  let count: number = 0;
  if (resultSet.goToNextRow()) {
    count = resultSet.getLong(0);
  }
  resultSet.close();

  if (count > 0) {
    await updateDescriptions(store);
    return;
  }

  let exercises: Array<relationalStore.ValuesBucket> = [
    { name: '俯卧撑', category: 'chest', categoryName: '胸部', description: '双手撑地略宽于肩，身体保持一条直线。屈臂下降至胸部接近地面，再推起还原。主要锻炼胸大肌、三角肌前束和肱三头肌。注意收紧核心，避免塌腰或撅臀。', defaultSets: 3, defaultReps: 15, defaultDuration: 0, type: 'count' },
    { name: '哑铃飞鸟', category: 'chest', categoryName: '胸部', description: '站姿，双脚与肩同宽，身体微前倾。双手各持哑铃，手臂自然下垂。保持肘部微屈，双臂向两侧抬起至与肩平齐，感受胸肌拉伸和收缩。动作过程中保持肩胛骨稳定，避免耸肩借力。主要锻炼胸大肌和三角肌前束。', defaultSets: 3, defaultReps: 12, defaultDuration: 0, type: 'count' },
    { name: '杠铃深蹲', category: 'leg', categoryName: '腿部', description: '杠铃置于斜方肌上部，双手握紧固定。双脚略宽于肩站立，脚尖外展15-30度。屈髋屈膝下蹲至大腿与地面平行或略低，膝盖方向与脚尖一致。挺胸收腹，重心落在全脚掌。站起时臀部和股四头肌同时发力，是发展下肢力量和围度的王牌动作。', defaultSets: 5, defaultReps: 12, defaultDuration: 0, type: 'count' },
    { name: '弓步蹲', category: 'leg', categoryName: '腿部', description: '自然站立，一脚向前迈出一大步。下蹲至前腿大腿平行地面、后腿膝盖接近地面。前脚膝盖不超过脚尖，躯干保持直立。交替双腿进行，锻炼股四头肌、臀大肌和核心稳定性。', defaultSets: 3, defaultReps: 12, defaultDuration: 0, type: 'count' },
    { name: '靠墙静蹲', category: 'leg', categoryName: '腿部', description: '背靠墙壁，双脚前移约两步距离。缓慢下蹲至大腿与地面平行，保持膝盖角度约90度。全程背部紧贴墙面，双手自然放在大腿上。此动作为等长收缩训练，对膝关节康复和股四头肌耐力提升效果显著。', defaultSets: 3, defaultReps: 0, defaultDuration: 30, type: 'timer' },
    { name: '仰卧起坐', category: 'abs', categoryName: '腹部', description: '仰卧屈膝，双脚平放地面，双手轻扶耳侧。呼气时收缩腹肌，卷起上半身至肩胛骨离地。吸气时缓慢还原，但不要完全躺平。注意不要用手拉头部，避免颈部发力。', defaultSets: 3, defaultReps: 20, defaultDuration: 0, type: 'count' },
    { name: '平板支撑', category: 'abs', categoryName: '腹部', description: '双前臂撑地，肘部位于肩膀正下方，双脚与肩同宽。身体从头到脚保持一条直线，收紧腹部和臀部，避免塌腰或弓背。保持均匀呼吸，不要憋气。此动作全面锻炼核心肌群的稳定性。', defaultSets: 3, defaultReps: 0, defaultDuration: 45, type: 'timer' },
    { name: '卷腹', category: 'abs', categoryName: '腹部', description: '仰卧屈膝，双手轻放胸前或耳侧。呼气时收缩腹肌，仅将肩胛骨抬离地面，下背部保持贴地。动作幅度不必过大，重点感受腹肌的收缩挤压。比仰卧起坐更安全，对腰椎压力更小。', defaultSets: 3, defaultReps: 15, defaultDuration: 0, type: 'count' },
    { name: '引体向上', category: 'back', categoryName: '背部', description: '双手正握单杠，握距略宽于肩，身体自然悬垂。背部发力将身体上拉至下巴超过横杆，缓慢下放还原。初学者可使用弹力带辅助或做反向引体。主要锻炼背阔肌、菱形肌和肱二头肌。', defaultSets: 3, defaultReps: 10, defaultDuration: 0, type: 'count' },
    { name: '俯身划船', category: 'back', categoryName: '背部', description: '双脚与肩同宽站立，屈髋俯身至上半身接近与地面平行。双手持哑铃自然下垂，背部发力将哑铃拉向腰部两侧，肩胛骨充分收紧。缓慢下放还原，感受背阔肌的拉伸。保持腰背挺直，避免弓背借力。', defaultSets: 3, defaultReps: 12, defaultDuration: 0, type: 'count' },
    { name: '开合跳', category: 'cardio', categoryName: '有氧', description: '自然站立，跳起时双脚向两侧打开同时双臂上举过头顶。再次跳起时双脚并拢、双臂还原体侧。保持节奏均匀，前脚掌着地缓冲。此动作可快速提升心率，是热身和燃脂的经典动作。', defaultSets: 3, defaultReps: 0, defaultDuration: 30, type: 'timer' },
    { name: '高抬腿', category: 'cardio', categoryName: '有氧', description: '原地跑步姿势，交替将膝盖抬至腰部以上高度。手臂自然摆动配合，前脚掌着地，保持身体直立不要前倾。速度由慢到快逐渐加速，注意呼吸节奏。锻炼髋屈肌和心肺耐力。', defaultSets: 3, defaultReps: 0, defaultDuration: 30, type: 'timer' },
    { name: '波比跳', category: 'cardio', categoryName: '有氧', description: '站立→下蹲双手撑地→双脚后跳成俯卧撑→做一个俯卧撑→双脚回收→起身跳跃。这是全身性高强度动作，同时锻炼心肺、力量和爆发力。初学者可省略俯卧撑或跳跃环节，逐步进阶完整动作。', defaultSets: 3, defaultReps: 10, defaultDuration: 0, type: 'count' },
    { name: '跳绳', category: 'cardio', categoryName: '有氧', description: '双手握绳柄，大臂夹紧身体两侧，手腕发力摇绳。跳跃高度控制在2-3厘米，前脚掌轻柔着地，膝盖微屈缓冲。保持均匀节奏，不要跳太高。跳绳是高效燃脂运动，10分钟跳绳约等于30分钟慢跑。', defaultSets: 3, defaultReps: 0, defaultDuration: 60, type: 'timer' },
    { name: '颈部拉伸', category: 'stretch', categoryName: '拉伸', description: '坐姿或站姿，右手轻轻将头部向右侧拉伸，感受左侧颈部肌肉拉伸感。保持15-20秒后换边。也可以做前屈和后仰拉伸。动作要缓慢轻柔，不要用力过猛。适合久坐办公人群缓解颈部僵硬。', defaultSets: 2, defaultReps: 0, defaultDuration: 20, type: 'timer' },
    { name: '体前屈', category: 'stretch', categoryName: '拉伸', description: '双脚并拢站立，双腿伸直。上身缓慢前屈，双手尽量触碰脚尖或地面。感受大腿后侧和下背部的拉伸感。保持呼吸放松，不要弹震式拉伸。如果柔韧性不足，可以微屈膝盖循序渐进。', defaultSets: 2, defaultReps: 0, defaultDuration: 30, type: 'timer' },
    { name: '肩部拉伸', category: 'stretch', categoryName: '拉伸', description: '一臂伸直横过胸前，另一手在肘部将其向身体方向按压。感受肩后部和三角肌的拉伸感，保持15-20秒后换边。也可以做手臂上举后弯拉伸前三角肌。训练前后进行肩部拉伸可有效预防肩关节损伤。', defaultSets: 2, defaultReps: 0, defaultDuration: 20, type: 'timer' },
    { name: '全身拉伸', category: 'stretch', categoryName: '拉伸', description: '站姿，双手十指交叉举过头顶，掌心向上，踮起脚尖向上伸展全身。保持5-10秒后放松。然后做体侧屈、体转运动，依次拉伸躯干各肌群。训练结束后进行全身拉伸可促进恢复、减少肌肉酸痛。', defaultSets: 2, defaultReps: 0, defaultDuration: 30, type: 'timer' }
  ];

  for (let i: number = 0; i < exercises.length; i++) {
    await store.insert('exercise', exercises[i]);
  }
}

async function updateDescriptions(store: relationalStore.RdbStore): Promise<void> {
  // 先更新运动名称和参数
  let updates: Array<{ oldName: string, newName: string, sets: number, reps: number, desc: string }> = [
    {
      oldName: '上斜推胸',
      newName: '哑铃飞鸟',
      sets: 3,
      reps: 12,
      desc: '站姿，双脚与肩同宽，身体微前倾。双手各持哑铃，手臂自然下垂。保持肘部微屈，双臂向两侧抬起至与肩平齐，感受胸肌拉伸和收缩。动作过程中保持肩胛骨稳定，避免耸肩借力。主要锻炼胸大肌和三角肌前束。'
    },
    {
      oldName: '深蹲',
      newName: '杠铃深蹲',
      sets: 5,
      reps: 12,
      desc: '杠铃置于斜方肌上部，双手握紧固定。双脚略宽于肩站立，脚尖外展15-30度。屈髋屈膝下蹲至大腿与地面平行或略低，膝盖方向与脚尖一致。挺胸收腹，重心落在全脚掌。站起时臀部和股四头肌同时发力，是发展下肢力量和围度的王牌动作。'
    }
  ];

  for (let i: number = 0; i < updates.length; i++) {
    let update = updates[i];
    let sql: string = "UPDATE exercise SET name = '" + update.newName + 
                      "', defaultSets = " + update.sets.toString() + 
                      ", defaultReps = " + update.reps.toString() + 
                      ", description = '" + update.desc + 
                      "' WHERE name = '" + update.oldName + "'";
    await store.executeSql(sql);
  }

  let descriptions: Map<string, string> = new Map([
    ['俯卧撑', '双手撑地略宽于肩，身体保持一条直线。屈臂下降至胸部接近地面，再推起还原。主要锻炼胸大肌、三角肌前束和肱三头肌。注意收紧核心，避免塌腰或撅臀。'],
    ['哑铃飞鸟', '站姿，双脚与肩同宽，身体微前倾。双手各持哑铃，手臂自然下垂。保持肘部微屈，双臂向两侧抬起至与肩平齐，感受胸肌拉伸和收缩。动作过程中保持肩胛骨稳定，避免耸肩借力。主要锻炼胸大肌和三角肌前束。'],
    ['杠铃深蹲', '杠铃置于斜方肌上部，双手握紧固定。双脚略宽于肩站立，脚尖外展15-30度。屈髋屈膝下蹲至大腿与地面平行或略低，膝盖方向与脚尖一致。挺胸收腹，重心落在全脚掌。站起时臀部和股四头肌同时发力，是发展下肢力量和围度的王牌动作。'],
    ['弓步蹲', '自然站立，一脚向前迈出一大步。下蹲至前腿大腿平行地面、后腿膝盖接近地面。前脚膝盖不超过脚尖，躯干保持直立。交替双腿进行，锻炼股四头肌、臀大肌和核心稳定性。'],
    ['靠墙静蹲', '背靠墙壁，双脚前移约两步距离。缓慢下蹲至大腿与地面平行，保持膝盖角度约90度。全程背部紧贴墙面，双手自然放在大腿上。此动作为等长收缩训练，对膝关节康复和股四头肌耐力提升效果显著。'],
    ['仰卧起坐', '仰卧屈膝，双脚平放地面，双手轻扶耳侧。呼气时收缩腹肌，卷起上半身至肩胛骨离地。吸气时缓慢还原，但不要完全躺平。注意不要用手拉头部，避免颈部发力。'],
    ['平板支撑', '双前臂撑地，肘部位于肩膀正下方，双脚与肩同宽。身体从头到脚保持一条直线，收紧腹部和臀部，避免塌腰或弓背。保持均匀呼吸，不要憋气。此动作全面锻炼核心肌群的稳定性。'],
    ['卷腹', '仰卧屈膝，双手轻放胸前或耳侧。呼气时收缩腹肌，仅将肩胛骨抬离地面，下背部保持贴地。动作幅度不必过大，重点感受腹肌的收缩挤压。比仰卧起坐更安全，对腰椎压力更小。'],
    ['引体向上', '双手正握单杠，握距略宽于肩，身体自然悬垂。背部发力将身体上拉至下巴超过横杆，缓慢下放还原。初学者可使用弹力带辅助或做反向引体。主要锻炼背阔肌、菱形肌和肱二头肌。'],
    ['俯身划船', '双脚与肩同宽站立，屈髋俯身至上半身接近与地面平行。双手持哑铃自然下垂，背部发力将哑铃拉向腰部两侧，肩胛骨充分收紧。缓慢下放还原，感受背阔肌的拉伸。保持腰背挺直，避免弓背借力。'],
    ['开合跳', '自然站立，跳起时双脚向两侧打开同时双臂上举过头顶。再次跳起时双脚并拢、双臂还原体侧。保持节奏均匀，前脚掌着地缓冲。此动作可快速提升心率，是热身和燃脂的经典动作。'],
    ['高抬腿', '原地跑步姿势，交替将膝盖抬至腰部以上高度。手臂自然摆动配合，前脚掌着地，保持身体直立不要前倾。速度由慢到快逐渐加速，注意呼吸节奏。锻炼髋屈肌和心肺耐力。'],
    ['波比跳', '站立→下蹲双手撑地→双脚后跳成俯卧撑→做一个俯卧撑→双脚回收→起身跳跃。这是全身性高强度动作，同时锻炼心肺、力量和爆发力。初学者可省略俯卧撑或跳跃环节，逐步进阶完整动作。'],
    ['跳绳', '双手握绳柄，大臂夹紧身体两侧，手腕发力摇绳。跳跃高度控制在2-3厘米，前脚掌轻柔着地，膝盖微屈缓冲。保持均匀节奏，不要跳太高。跳绳是高效燃脂运动，10分钟跳绳约等于30分钟慢跑。'],
    ['颈部拉伸', '坐姿或站姿，右手轻轻将头部向右侧拉伸，感受左侧颈部肌肉拉伸感。保持15-20秒后换边。也可以做前屈和后仰拉伸。动作要缓慢轻柔，不要用力过猛。适合久坐办公人群缓解颈部僵硬。'],
    ['体前屈', '双脚并拢站立，双腿伸直。上身缓慢前屈，双手尽量触碰脚尖或地面。感受大腿后侧和下背部的拉伸感。保持呼吸放松，不要弹震式拉伸。如果柔韧性不足，可以微屈膝盖循序渐进。'],
    ['肩部拉伸', '一臂伸直横过胸前，另一手在肘部将其向身体方向按压。感受肩后部和三角肌的拉伸感，保持15-20秒后换边。也可以做手臂上举后弯拉伸前三角肌。训练前后进行肩部拉伸可有效预防肩关节损伤。'],
    ['全身拉伸', '站姿，双手十指交叉举过头顶，掌心向上，踮起脚尖向上伸展全身。保持5-10秒后放松。然后做体侧屈、体转运动，依次拉伸躯干各肌群。训练结束后进行全身拉伸可促进恢复、减少肌肉酸痛。']
  ]);

  let names: Array<string> = [
    '俯卧撑', '哑铃飞鸟', '杠铃深蹲', '弓步蹲', '靠墙静蹲',
    '仰卧起坐', '平板支撑', '卷腹', '引体向上', '俯身划船',
    '开合跳', '高抬腿', '波比跳', '跳绳',
    '颈部拉伸', '体前屈', '肩部拉伸', '全身拉伸'
  ];
  for (let i: number = 0; i < names.length; i++) {
    let desc: string | undefined = descriptions.get(names[i]);
    if (desc !== undefined) {
      let sql: string = "UPDATE exercise SET description = '" + desc + "' WHERE name = '" + names[i] + "'";
      await store.executeSql(sql);
    }
  }
}
