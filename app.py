import os
import hmac
import hashlib
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError
from fastapi import FastAPI, Request, Header, HTTPException
from dotenv import load_dotenv
from typing import Optional

# .env 파일 로드
load_dotenv()

# 환경 변수에서 Slack 토큰과 서명 비밀 가져오기
SLACK_BOT_TOKEN = os.getenv("SLACK_BOT_TOKEN")
SLACK_SIGNING_SECRET = os.getenv("SLACK_SIGNING_SECRET")

# Slack 클라이언트 초기화
client = WebClient(token=SLACK_BOT_TOKEN)

app = FastAPI()


def verify_slack_signature(request: Request, slack_signature: str, slack_timestamp: str):
    # Slack 서명 검증
    req_body = request.body()
    sig_basestring = f"v0:{slack_timestamp}:{req_body}"
    my_signature = "v0=" + hmac.new(
        SLACK_SIGNING_SECRET.encode(),
        sig_basestring.encode(),
        hashlib.sha256
    ).hexdigest()

    if not hmac.compare_digest(my_signature, slack_signature):
        raise HTTPException(status_code=400, detail="Invalid Slack signature")

@app.post("/slack/events")
async def slack_events(
        request: Request,
        x_slack_signature: Optional[str] = Header(None),
        x_slack_request_timestamp: Optional[str] = Header(None)
):
    # # Slack에서 오는 요청의 서명 검증
    # if not x_slack_signature or not x_slack_request_timestamp:
    #     raise HTTPException(status_code=400, detail="Missing Slack signature headers")
    #
    # # 서명 검증
    # verify_slack_signature(request, x_slack_signature, x_slack_request_timestamp)

    # Slack 이벤트 처리
    data = await request.json()

    # Slack의 URL 검증 challenge 처리
    if "challenge" in data:
        return {"challenge": data["challenge"]}

    # 메시지가 봇에 의해 작성된 것인지 확인 (자기 자신이 보낸 메시지인지 체크)
    if "bot_id" in data.get("event", {}):
        return {"status": "ignored"}

    # 사용자로부터 메시지가 온 경우 처리
    if "event" in data and data["event"]["type"] == "message" and "text" in data["event"]:
        user_message = data["event"]["text"]  # 사용자가 입력한 메시지
        channel_id = data["event"]["channel"]  # 메시지가 온 채널 ID

        # 사용자가 '/write' 명령어를 입력했을 때 반응
        if user_message.lower() == "/write":
            try:
                # 사용자에게 응답 메시지 보내기
                client.chat_postMessage(
                    channel=channel_id,
                    text="글을 작성해 주세요!"
                )
            except SlackApiError as e:
                print(f"Error posting message: {e.response['error']}")

    return {"status": "ok"}

