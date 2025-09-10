require "test_helper"
require "benchmark"

class MembershipPerformanceTest < ActiveSupport::TestCase
  # 성능 벤치마크 테스트

  def setup
    # 성능 테스트용 대량 데이터 준비
    @users = []
    100.times do |i|
      @users << User.create!(
        email: "perf_#{i}@example.com",
        name: "Performance User #{i}"
      )
    end
  end

  test "membership creation performance benchmark" do
    times = Benchmark.measure do
      @users.each do |user|
        user.memberships.create!(
          membership_type: [ "basic", "premium" ].sample,
          start_date: Date.current,
          end_date: Date.current + 30.days,
          price: 49000,
          status: "active"
        )
      end
    end

    puts "\n=== Membership Creation Benchmark ==="
    puts "Created #{@users.size} memberships in #{times.real.round(3)}s"
    puts "Average: #{(times.real / @users.size * 1000).round(2)}ms per membership"

    # 성능 임계값 검증 (100개 멤버십 생성이 2초 이내)
    assert times.real < 2.0,
      "Membership creation too slow: #{times.real}s for #{@users.size} items"
  end

  test "membership query performance with different scopes" do
    # 테스트 데이터 준비
    @users.each_with_index do |user, index|
      membership_type = index.even? ? "basic" : "premium"
      status = index % 3 == 0 ? "expired" : "active"

      user.memberships.create!(
        membership_type: membership_type,
        start_date: Date.current - rand(60).days,
        end_date: Date.current + rand(60).days,
        price: membership_type == "premium" ? 99000 : 49000,
        status: status
      )
    end

    queries = {
      "All memberships" => -> { Membership.all.to_a },
      "Active memberships" => -> { Membership.active.to_a },
      "Premium memberships" => -> { Membership.premium.to_a },
      "Active premium" => -> { Membership.active.premium.to_a },
      "With users (N+1 risk)" => -> { Membership.all.map(&:user) },
      "With includes (optimized)" => -> { Membership.includes(:user).map(&:user) }
    }

    puts "\n=== Query Performance Benchmark ==="

    queries.each do |name, query|
      times = Benchmark.measure { 5.times { query.call } }
      avg_time = times.real / 5

      puts "#{name}: #{avg_time.round(4)}s average"

      # N+1 쿼리 검증 (includes 사용한 것이 더 빨라야 함)
      if name.include?("optimized")
        @optimized_time = avg_time
      elsif name.include?("N+1 risk")
        @n_plus_one_time = avg_time
      end
    end

    # N+1 최적화 효과 검증
    if @optimized_time && @n_plus_one_time
      improvement_ratio = @n_plus_one_time / @optimized_time
      puts "Optimization improvement: #{improvement_ratio.round(2)}x faster"

      assert improvement_ratio > 1.5,
        "Includes optimization should be significantly faster"
    end
  end

  test "concurrent access performance" do
    user = @users.first

    # 동시 접근 시뮬레이션
    threads_count = 10
    operations_per_thread = 10

    start_time = Time.current

    threads = []
    threads_count.times do |i|
      threads << Thread.new do
        operations_per_thread.times do |j|
          # 멤버십 조회
          user.memberships.active.first

          # 권한 확인
          membership = user.memberships.last
          membership&.can_use?("study")
        end
      end
    end

    threads.each(&:join)

    end_time = Time.current
    total_time = end_time - start_time
    total_operations = threads_count * operations_per_thread

    puts "\n=== Concurrent Access Benchmark ==="
    puts "#{total_operations} operations in #{total_time.round(3)}s"
    puts "#{(total_operations / total_time).round(1)} operations/second"

    # 동시성 성능 검증
    assert total_time < 5.0,
      "Concurrent access too slow: #{total_time}s for #{total_operations} operations"
  end

  test "memory usage monitoring" do
    # 메모리 사용량 모니터링 (간단한 버전)
    initial_memory = get_memory_usage

    # 대량 데이터 처리
    large_dataset = []
    1000.times do |i|
      membership_data = {
        id: i,
        membership_type: [ "basic", "premium" ].sample,
        user_name: "User #{i}",
        available_features: [ "study", "conversation", "analysis" ].sample(rand(1..3))
      }
      large_dataset << membership_data
    end

    # JSON 변환 (실제 API 응답과 유사)
    json_data = large_dataset.map(&:to_json)

    final_memory = get_memory_usage
    memory_increase = final_memory - initial_memory

    puts "\n=== Memory Usage Test ==="
    puts "Initial memory: #{initial_memory}MB"
    puts "Final memory: #{final_memory}MB"
    puts "Memory increase: #{memory_increase}MB"

    # 메모리 누수 검증 (100MB 이하 증가)
    assert memory_increase < 100,
      "Memory usage increased too much: #{memory_increase}MB"
  end

  private

  def get_memory_usage
    # 간단한 메모리 사용량 측정 (리눅스/맥 환경)
    return 0 unless RUBY_PLATFORM.include?("darwin") || RUBY_PLATFORM.include?("linux")

    pid = Process.pid
    if RUBY_PLATFORM.include?("darwin")
      `ps -o rss= -p #{pid}`.to_i / 1024.0  # KB to MB
    else
      `cat /proc/#{pid}/status | grep VmRSS`.split[1].to_i / 1024.0
    end
  rescue
    0
  end
end
