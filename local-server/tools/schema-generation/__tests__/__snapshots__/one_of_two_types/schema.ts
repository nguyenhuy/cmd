export interface NumberType {
  type: "number";
  value: number;
}
export interface BooleanType {
  type: "boolean";
  value: boolean;
}
export type ValueType = NumberType | BooleanType;
