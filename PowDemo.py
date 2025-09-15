from hashlib import sha256
import time

def proof_of_work(name, difficulty):
    nonce = 0
    hash = sha256(name.encode()).hexdigest()
    while not hash.startswith('0' * difficulty):
        nonce += 1
        hash = sha256((name + str(nonce)).encode()).hexdigest()
    return hash, nonce

if __name__ == '__main__':
    name = 'test'
    difficulty = 5
    # 记录开始时间
    start_time = time.time()
    hash, nonce = proof_of_work(name, difficulty)
    # 记录结束时间
    end_time = time.time()
    # 计算执行时间
    execution_time = end_time - start_time
    print(f'{name} {hash} {nonce}')
    print(f'运算时间: {execution_time:.6f} 秒')