import { poolCalcScore } from './consine_worker';
import * as funcs from './neo4j_functions';
import { printResults } from './neo4j_index';
import {
  userFunctions,
  createFemale,
  createMale,
  createGroupA,
  createGroupB,
  validFriends,
  createRandom,
  userdIdToType,
} from './person';
import * as neo4j from 'neo4j-driver';

const Pool = require(`multiprocessing`).Pool;

let results: neo4j.QueryResult;

const calcAvg = async (
  result: neo4j.QueryResult,
  cosineSimilarityThreshhold: number = 0.5,
) => {
  console.log(`calculating average`);

  const start_time = performance.now();
  let records = result.records;

  function generatePairs(items: any) {
    const pairs = [];

    for (let i = 0; i < items.length; i++) {
      for (let j = i + 1; j < items.length; j++) {
        if (items[i] !== items[j]) {
          pairs.push([items[i], items[j]]);
        }
      }
    }

    return pairs;
  }

  const items = records.map((record) => {
    return {
      type: record.get(`n.userId`),
      embedding: record.get(`n.embedding`),
    };
  });

  const pairs = generatePairs(items);

  console.log(`pairs.length`, pairs.length);

  // const pool = new Pool(10);
  // const scores = await pool.map(
  // pairs.map((pairs) => {
  //   const ntype: any = pairs[0].type;
  //   const mtype: any = pairs[1].type;
  //   const nembedding: any = pairs[0].embedding;
  //   const membedding: any = pairs[1].embedding;
  //   return { ntype, mtype, nembedding, membedding };
  // }),
  //   __dirname + `/consine_worker`,
  // );

  const scores = pairs
    .map((pairs) => {
      const ntype: any = pairs[0].type;
      const mtype: any = pairs[1].type;
      const nembedding: any = pairs[0].embedding;
      const membedding: any = pairs[1].embedding;
      return { ntype, mtype, nembedding, membedding };
    })
    .map((args) => {
      return poolCalcScore(
        args.ntype,
        args.mtype,
        args.nembedding,
        args.membedding,
      );
    });

  let length = 0;
  let total = 0;

  for (let score of scores) {
    const ntype = score.ntype;
    const mtype = score.mtype;

    const simScore = score.simScore;

    if (simScore <= cosineSimilarityThreshhold) {
      continue;
    }

    if (validFriends(ntype, mtype)) total += 1;
    length += 1;
  }

  console.log(`total`, total, `length`, length);
  console.log(`--- calcAvg`);
  console.log(`run`, performance.now() - start_time);

  return total / length;
};

function cleanPerm(perm: number[]): number[] {
  if (perm.length > 1 && perm[perm.length - 1] == 0) {
    return cleanPerm(perm.slice(0, perm.length - 1));
  }
  return perm;
}
function generatePermutations(values: number[], length: number): number[][] {
  const permutationsSet = new Set<string>();

  function generateHelper(current: number[]) {
    if (current.length === length) {
      permutationsSet.add(JSON.stringify(cleanPerm(current)));
      return;
    }

    for (let i = 0; i < values.length; i++) {
      generateHelper([...current, values[i]]);
    }
  }

  generateHelper([]);

  return Array.from(permutationsSet).map((val) => JSON.parse(val));
}

export const nodeembeddings = async (
  permutations: any = false,
  createData: boolean = false,
) => {
  userFunctions.length = 0;

  userFunctions.push(createFemale);
  userFunctions.push(createMale);
  userFunctions.push(createGroupA);
  userFunctions.push(createGroupB);
  // userFunctions.push(createRandom);

  if (createData) {
    await funcs.createData({
      deleteData: true,
      nodesNum: 200,
      edgesNum: 20,
    });
    results = await funcs.createFriends();
  }

  const test_attributes: string[] = await funcs.getAttributeKeys();
  results = await funcs.createGraph(`myGraph`, test_attributes);

  if (permutations == false) {
    permutations = generatePermutations([0, 1, 0.5], 3);
  }
  console.log(`permutations: ${JSON.stringify(permutations)}`);
  // if (1 == 1) process.exit(1);

  results = await funcs.run(
    `
    CALL gds.articleRank.mutate('myGraph', 
      {  
        scaler: "MinMax",
        nodeLabels: ['Person'],
        relationshipTypes: ['FRIENDS'],
        // relationshipTypes: ['FEEDBACK'],
        // relationshipWeightProperty: 'score',
        mutateProperty: 'priority' 
      }
    )
    YIELD nodePropertiesWritten, ranIterations
  `,
  );

  results = await funcs.run(
    `
    CALL gds.louvain.mutate('myGraph', 
    {  
      nodeLabels: ['Person'],
      relationshipTypes: ['FRIENDS'],
      // relationshipTypes: ['FEEDBACK'],
      // relationshipWeightProperty: 'score',
      mutateProperty: 'community' 
    }
    )
  `,
  );

  let resultList: any[] = [];

  // [0, 1, 0.5]
  for (let propertyRatio of [0]) {
    for (let nodeSelfInfluence of [1]) {
      for (let perm of permutations) {
        resultList.push(
          await generateEmbedding(perm, propertyRatio, nodeSelfInfluence),
        );
      }
    }
  }

  resultList.sort((item1, item2) => {
    if (item1.avg != item2.avg) {
      return item1.avg - item2.avg;
    }
    return item1.avg * item1.length - item2.avg * item2.length;
  });

  // const winner = resultList[resultList.length - 1].perm;
  // console.log();
  // console.log(`printing winner`);
  // await generateEmbedding(
  //   winner,
  //   winner.propertyRatio,
  //   winner.nodeSelfInfluence,
  // );

  console.log();
  // for (let result of resultList) {
  //   console.log(
  //     `avg=${result.avg.toFixed(2)}\t perm=${JSON.stringify(
  //       result.perm,
  //     )}\t pr=${result.propertyRatio}\t nsi=${
  //       result.nodeSelfInfluence
  //     }\t leng=${result.length}\t s=${(result.avg * result.length).toFixed(
  //       2,
  //     )} `,
  //   );
  // }

  // resultList = resultList.filter((item) => item.avg >= 0.5);

  console.table(resultList);
  console.log(`permutations.length: ${permutations.length}`);

  return resultList;
};

const generateEmbedding = async (
  perm: number[],
  propertyRatio: number = 0,
  nodeSelfInfluence: number = 1,
) => {
  console.log(`perm: ${JSON.stringify(perm)}`);

  results = await funcs.run(
    `
        MATCH (n)
        REMOVE n.embedding
        `,
  );

  results = await funcs.run(
    `
      CALL gds.fastRP.write('myGraph',
      {
        nodeLabels: ['Person'],
        relationshipTypes: ['FRIENDS'],
        // relationshipWeightProperty: 'score',
        featureProperties: ['values','priority','community'],
        propertyRatio: ${propertyRatio},
        nodeSelfInfluence: ${nodeSelfInfluence},
        embeddingDimension: 15,
        randomSeed: 42,
        iterationWeights: ${JSON.stringify(perm)},
        writeProperty: 'embedding'
      }
      )
    `,
  );

  results = await funcs.run(
    `
      MATCH (n:Person)
      WHERE n.embedding IS NOT NULL
      return
      n.userId, 
      n.embedding
      // LIMIT 200
    `,
  );

  // printResults(results, 50, 0);

  const avg: number = (await calcAvg(results, 0)) as number;

  console.log();
  console.log(`the avg is:`, avg);
  console.log();

  return {
    avg,
    perm,
    length: results.records.length,
    propertyRatio,
    nodeSelfInfluence,
    score: avg * results.records.length,
  };
};

export const main = async () => {
  let perms: any = [[1, 0.5, 0]];
  // perms = false;
  const resultsList = await nodeembeddings(perms, true);

  // const resultsListOther = await nodeembeddings(
  //   !gender,
  //   resultsList.slice(-3).map((val) => val.perm),
  // );
  // console.log();
  // console.log();

  // console.log(`resultsList`);
  // for (let result of resultsList.slice(-3)) {
  //   console.log(`avg: ${result.avg} for ${JSON.stringify(result.perm)}`);
  // }

  // console.log(`resultsListOther`);
  // for (let result of resultsListOther) {
  //   console.log(`avg: ${result.avg} for ${JSON.stringify(result.perm)}`);
  // }
};
