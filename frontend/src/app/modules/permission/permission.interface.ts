export interface IRole {
  id: number;
  name: string;
  type: 'USER'|'GROUP';
  permissionsNbr?: number;
}
