export interface NumberType {
  type: "number";
  value: number;
}
export interface BooleanType {
  type: "boolean";
  value: boolean;
}
export interface ValueType {
  value: BooleanType | NumberType;
}
