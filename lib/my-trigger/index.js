const aws = require("aws-sdk");
const unzipper = require("unzipper");

const s3 = new aws.S3();

const zipObjectUrl = process.env.s3ObjectUrl;

exports.handler = async () => {
  console.log("zipObjectUrl: ", zipObjectUrl);
  const [bucketKey, zipKey] = zipObjectUrl.split("/assets/");
  const bucketName = bucketKey.replace("s3://", "");
  const [folderName] = zipKey.split(".zip");

  console.log(folderName, bucketName);

  const params = {
    Key: "assets/" + zipKey,
    Bucket: bucketName,
  };

  const zip = s3
    .getObject(params)
    .createReadStream()
    .pipe(unzipper.Parse({ forceStream: true }));

  const promises = [];

  let num = 0;

  for await (const e of zip) {
    const entry = e;

    const fileName = entry.path;
    const type = entry.type;
    if (type === "File") {
      const uploadParams = {
        Bucket: bucketName,
        Key: "assets/" + folderName + "/" + fileName,
        Body: entry,
      };

      promises.push(s3.upload(uploadParams).promise());
      num++;
    } else {
      entry.autodrain();
    }
  }

  await Promise.all(promises);
};
