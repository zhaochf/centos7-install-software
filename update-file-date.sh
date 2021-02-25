#! /bin/bash

FILE_PATH=$1
SOURCE_DATE=$2
TARGET_DATE=$3

echo "Starting update files date and name..."
echo "Update file path: $FILE_PATH, source date: $SOURCE_DATE, target date: $TARGET_DATE"

if [ ! -d "$FILE_PATH" ];then
  echo "[ERROR] The path: $FILE_PATH not exists."
  exit 1
fi

if [ -z "$SOURCE_DATE" ]; then
  echo "[ERROR] The source date is empty."
  exit 1
fi

if [ -z "$TARGET_DATE" ]; then
  echo "[ERROR] The target date is empty."
  exit 1
fi

FRONT_STRING=""
SOURCE_STRING=""
TARGET_STRING=""

FILE_PATHS=$(ls "$FILE_PATH"/*.txt)
i=100
for FILE in $FILE_PATHS; do
  FILE_NAME=${FILE##*/}
  if [ "${FILE_NAME:14:8}" != "$SOURCE_DATE" ];then
    continue
  fi
  i=`expr $i + 1`;
  # read first line
  while read -r line; do
    FRONT_STRING=${line:0:28}
    SOURCE_STRING="$FRONT_STRING$SOURCE_DATE"
    TARGET_STRING="$FRONT_STRING$TARGET_DATE"
    break
  done < "$FILE"

  sed -i ".$SOURCE_DATE" "1s/$SOURCE_STRING/$TARGET_STRING/" "$FILE"

  NEW_FILE_NAME="${FILE_NAME:0:14}$TARGET_DATE${FILE_NAME:22:4}$i"0.txt
  mv "$FILE" "$FILE_PATH/$NEW_FILE_NAME"
done

echo ""
echo ""
echo ""
echo "Finished update file date."
exit 0

