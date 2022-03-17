import * as cdk from "@aws-cdk/core";
import * as lambda from "@aws-cdk/aws-lambda";
import * as apigw from "@aws-cdk/aws-apigateway";
import * as assets from "@aws-cdk/aws-s3-assets";
import * as appsync from "@aws-cdk/aws-appsync";
import * as dynamodb from "@aws-cdk/aws-dynamodb";
import * as triggers from "@aws-cdk/triggers";

import { HitCounter } from "./hitcounter";
import { TableViewer } from "cdk-dynamo-table-viewer";

const path = require("path");

export class CdkWorkshopStack extends cdk.Stack {
  constructor(scope: cdk.App, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const searchResolversAsset = new assets.Asset(
      this,
      "ApiBatchedSearchResolversAsset",
      {
        path: path.join(__dirname, "/search-resolvers"),
      }
    );

    const hello = new lambda.Function(this, "HelloHandler", {
      runtime: lambda.Runtime.NODEJS_14_X,
      code: lambda.Code.fromAsset("lambda"),
      handler: "hello.handler",
      environment: {
        s3Url: searchResolversAsset.s3ObjectUrl,
      },
    });

    const helloWithCounter = new HitCounter(this, "HelloHitCounter", {
      downstream: hello,
    });

    // defines an API Gateway REST API resource backed by our "hello" function.
    new apigw.LambdaRestApi(this, "Endpoint", {
      handler: helloWithCounter.handler,
    });

    const tfn = new triggers.TriggerFunction(this, "MyTrigger", {
      runtime: lambda.Runtime.NODEJS_14_X,
      handler: "index.handler",
      code: lambda.Code.fromAsset(__dirname + "/my-trigger"),
      environment: {
        s3ObjectUrl: searchResolversAsset.s3ObjectUrl,
      },
      timeout: cdk.Duration.seconds(60),
      memorySize: 512,
    });

    searchResolversAsset.bucket.grantReadWrite(tfn);

    const layer = new lambda.LayerVersion(this, "uuidLayer", {
      code: lambda.Code.fromAsset(`${__dirname}/layers/unzipper.zip`),
      compatibleRuntimes: [lambda.Runtime.NODEJS_14_X],
      description: "uuid package and discount for product",
    });

    tfn.addLayers(layer);

    new TableViewer(this, "ViewHitCounter", {
      title: "Hello Hits",
      table: helloWithCounter.table,
      sortBy: "-hits",
    });

    new AppSyncBatchedResolverStack(
      this,
      "sample-nested",
      searchResolversAsset
    );
  }

  protected onPrepare(): void {
    const stack = this.node._actualNode as unknown as cdk.CfnStack;
    console.log(">>lib/cdk-workshop-stack::", "stack", stack); //TRACE
  }
}

export default class AppSyncBatchedResolverStack extends cdk.NestedStack {
  constructor(
    scope: cdk.Construct,
    id: string,
    searchResolversAsset: assets.Asset
  ) {
    super(scope, id);

    const api = new appsync.GraphqlApi(this, "Api", {
      name: "demo",
      schema: appsync.Schema.fromAsset(path.join(__dirname, "schema.graphql")),
      authorizationConfig: {
        defaultAuthorization: {
          authorizationType: appsync.AuthorizationType.IAM,
        },
      },
      xrayEnabled: true,
    });

    const demoTable = new dynamodb.Table(this, "DemoTable", {
      partitionKey: {
        name: "id",
        type: dynamodb.AttributeType.STRING,
      },
    });

    const demoDS = api.addDynamoDbDataSource("demoDataSource", demoTable);
    demoDS.createResolver({
      typeName: "Query",
      fieldName: "getDemos",
      requestMappingTemplate: appsync.MappingTemplate.dynamoDbScanTable(),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultList(),
    });

    const gdRes = demoDS.createResolver({
      typeName: "Query",
      fieldName: "getDemos2",
      requestMappingTemplate: appsync.MappingTemplate.dynamoDbScanTable(),
      // responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultList(),
    });

    const cfnResolver = (gdRes as any).resolver as appsync.CfnResolver;
    cfnResolver.responseMappingTemplateS3Location =
      "s3://" +
      searchResolversAsset.s3BucketName +
      "/assets/" +
      searchResolversAsset.assetHash +
      "/" +
      "Query.searchAllocations.res";

    // Resolver for the Mutation "addDemo" that puts the item into the DynamoDb table.
    demoDS.createResolver({
      typeName: "Mutation",
      fieldName: "addDemo",
      requestMappingTemplate: appsync.MappingTemplate.dynamoDbPutItem(
        appsync.PrimaryKey.partition("id").auto(),
        appsync.Values.projecting("input")
      ),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });
  }
}
