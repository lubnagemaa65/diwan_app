import { GoogleGenerativeAI } from '@google/generative-ai';
import config from '../config/config';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY as string);

/**
 * Get a maintenance triage suggestion from Gemini based on a problem description
 */
const getTriageSuggestion = async (
  problemDescription: string,
  deviceType: string
): Promise<string> => {
  const model = genAI.getGenerativeModel({ model: 'gemini-3.1-flash-lite' });

  const prompt = `أنت فني صيانة أجهزة حاسوب وطابعات ذو خبرة. بناءً على وصف المشكلة التالية لجهاز من نوع "${deviceType}"، اقترح السبب المحتمل للمشكلة وخطوات أولية لإصلاحها. اجعل الإجابة موجزة (3-5 نقاط كحد أقصى) وباللغة العربية فقط.

وصف المشكلة: "${problemDescription}"`;

  const result = await model.generateContent(prompt);
  const response = result.response;
  return response.text();
};

export default {
  getTriageSuggestion
};