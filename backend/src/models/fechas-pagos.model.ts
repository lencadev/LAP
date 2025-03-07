import {Entity, model, property, belongsTo, hasMany, hasOne} from '@loopback/repository';
import {PlanesPago} from './planes-pago.model';
import {Pagos} from './pagos.model';
import {Moras} from './moras.model';

@model({settings: {idInjection: false, mssql: {schema: 'dbo', table: 'FechasPagos'}}})
export class FechasPagos extends Entity {
  @property({
    type: 'number',
    jsonSchema: {nullable: false},
    precision: 10,
    scale: 0,
    generated: 1,
    id: 1,
    mssql: {columnName: 'Id', dataType: 'int', dataLength: null, dataPrecision: 10, dataScale: 0, nullable: 'NO', generated: 1},
  })
  id?: number;

  @property({
    type: 'date',
    required: true,
    jsonSchema: {nullable: false},
    generated: false,
    mssql: {columnName: 'FechaPago', dataType: 'date', dataLength: null, dataPrecision: null, dataScale: null, nullable: 'NO', generated: false},
  })
  fechaPago: string;
  @property({
    type: 'boolean',
    required: true,
    jsonSchema: {nullable: false},
    generated: false,
    mssql: {columnName: 'Estado', dataType: 'bit', dataLength: null, dataPrecision: null, dataScale: null, nullable: 'NO', generated: false},
  })
  estado: boolean;

  @property({
    type: 'string',
    jsonSchema: {nullable: true},
    precision: 19,
    scale: 13,
    generated: false,
    mssql: {columnName: 'Monto', dataType: 'decimal', dataLength: null, dataPrecision: 19, dataScale: 13, nullable: 'YES'},
  })
  monto?: string;
  

  @belongsTo(() => PlanesPago, {name: 'planPago'})
  planId: number;

  @hasMany(() => Pagos, {keyTo: 'idFechaPago'})
  pagos: Pagos[];

  @hasOne(() => Moras, {keyTo: 'idFechaPago'})
  moras: Moras;
  // Define well-known properties here

  // Indexer property to allow additional data
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  [prop: string]: any;

  constructor(data?: Partial<FechasPagos>) {
    super(data);
  }
}

export interface FechasPagosRelations {
  // describe navigational properties here
}

export type FechasPagosWithRelations = FechasPagos & FechasPagosRelations;
