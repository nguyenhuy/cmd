export interface Message {
  role: "system" | "user" | "assistant" | "function_call";
  single_value: "single_value";
}
